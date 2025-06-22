import Foundation

/// A least-recently-used (LRU) cache implementation with thread-safe access
public final class LRUCache<Key: Hashable & Sendable, Value: Sendable>: @unchecked Sendable {
    private let configuration: Configuration<Key, Value>
    private var dict: [Key: LRUNode<Key, Value>] = [:]
    private var head: LRUNode<Key, Value>?
    private var tail: LRUNode<Key, Value>?
    private var totalSize: Int = 0
    private let lock = NSLock()

    /// The maximum number of items in the cache
    public var max: Int? {
        configuration.max
    }

    /// The current number of items in the cache
    public var size: Int {
        lock.lock()
        defer { lock.unlock() }
        return dict.count
    }

    /// The total calculated size of all items in the cache
    public var calculatedSize: Int {
        lock.lock()
        defer { lock.unlock() }
        return totalSize
    }

    /// Initialize a new LRU cache with the given configuration
    public init(configuration: Configuration<Key, Value>) {
        self.configuration = configuration
    }

    /// Get a value from the cache
    public func get(_ key: Key, options: GetOptions? = nil) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = dict[key] else {
            return nil
        }

        let now = Date()

        if isStale(node, now: now) {
            let allowStale = options?.allowStale ?? configuration.allowStale
            let noDeleteOnStaleGet = options?.noDeleteOnStaleGet ?? configuration.noDeleteOnStaleGet

            if !noDeleteOnStaleGet {
                removeNode(node)
                dict.removeValue(forKey: key)

                if let size = node.size {
                    totalSize -= size
                }

                configuration.dispose?(node.value, key, .expire)
            }

            return allowStale ? node.value : nil
        }

        let updateAgeOnGet = options?.updateAgeOnGet ?? configuration.updateAgeOnGet
        if updateAgeOnGet && node.ttl != nil {
            node.insertTime = now
        }

        moveToHead(node)
        return node.value
    }

    /// Set a value in the cache
    public func set(_ key: Key, value: Value, ttl: TimeInterval? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()

        if configuration.ttlAutopurge {
            _purgeStale()
        }

        let itemSize = calculateSize(for: value, key: key)

        /// Check maxEntrySize constraint
        if let maxEntrySize = configuration.maxEntrySize, itemSize > maxEntrySize {
            /// Item too large, don't add it
            return
        }

        if let existingNode = dict[key] {
            /// Update size tracking
            if let oldSize = existingNode.size {
                totalSize -= oldSize
            }

            existingNode.value = value
            existingNode.size = itemSize
            totalSize += itemSize

            if !configuration.noUpdateTTL || existingNode.ttl == nil {
                existingNode.ttl = ttl ?? configuration.ttl
                existingNode.insertTime = existingNode.ttl != nil ? now : nil
            }

            moveToHead(existingNode)
            return
        }

        /// Check if we need to evict items to make space
        if let maxSize = configuration.maxSize {
            while totalSize + itemSize > maxSize && tail != nil {
                evictLRU()
            }
        }

        let newNode = LRUNode(key: key, value: value)
        newNode.ttl = ttl ?? configuration.ttl
        newNode.insertTime = newNode.ttl != nil ? now : nil
        newNode.size = itemSize

        dict[key] = newNode
        addToHead(newNode)
        totalSize += itemSize

        if let max = configuration.max, dict.count > max {
            evictLRU()
        }
    }

    /// Check if a key exists in the cache
    public func has(_ key: Key) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = dict[key] else {
            return false
        }

        if isStale(node) {
            if !configuration.noDeleteOnStaleGet {
                removeNode(node)
                dict.removeValue(forKey: key)

                if let size = node.size {
                    totalSize -= size
                }

                configuration.dispose?(node.value, key, .expire)
            }
            return false
        }

        if configuration.updateAgeOnHas && node.ttl != nil {
            node.insertTime = Date()
        }

        return true
    }

    /// Delete a key from the cache
    @discardableResult
    public func delete(_ key: Key) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = dict[key] else {
            return false
        }

        removeNode(node)
        dict.removeValue(forKey: key)

        if let size = node.size {
            totalSize -= size
        }

        configuration.dispose?(node.value, key, .delete)

        return true
    }

    /// Clear all items from the cache
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        for (key, node) in dict {
            configuration.dispose?(node.value, key, .delete)
        }

        dict.removeAll()
        head = nil
        tail = nil
        totalSize = 0
    }

    /// Get a value without updating its position in the LRU list
    public func peek(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return dict[key]?.value
    }

    private func addToHead(_ node: LRUNode<Key, Value>) {
        node.prev = nil
        node.next = head

        if let head = head {
            head.prev = node
        }

        head = node

        if tail == nil {
            tail = node
        }
    }

    private func removeNode(_ node: LRUNode<Key, Value>) {
        if node === head {
            head = node.next
        }
        if node === tail {
            tail = node.prev
        }

        node.prev?.next = node.next
        node.next?.prev = node.prev

        node.prev = nil
        node.next = nil
    }

    private func moveToHead(_ node: LRUNode<Key, Value>) {
        if node === head {
            return
        }

        removeNode(node)
        addToHead(node)
    }

    private func evictLRU() {
        guard let tailNode = tail else {
            return
        }

        removeNode(tailNode)
        dict.removeValue(forKey: tailNode.key)

        if let size = tailNode.size {
            totalSize -= size
        }

        configuration.dispose?(tailNode.value, tailNode.key, .evict)
    }

    /// Remove all stale entries
    public func purgeStale() {
        lock.lock()
        defer { lock.unlock() }
        _purgeStale()
    }
    
    private func _purgeStale() {
        let now = Date()
        var nodesToRemove: [LRUNode<Key, Value>] = []

        for (_, node) in dict where isStale(node, now: now) {
            nodesToRemove.append(node)
        }

        for node in nodesToRemove {
            removeNode(node)
            dict.removeValue(forKey: node.key)

            if let size = node.size {
                totalSize -= size
            }

            configuration.dispose?(node.value, node.key, .expire)
        }
    }

    /// Get the remaining TTL for a key
    public func getRemainingTTL(_ key: Key) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = dict[key],
              let ttl = node.ttl,
              let insertTime = node.insertTime else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(insertTime)
        let remaining = ttl - elapsed

        return remaining > 0 ? remaining : 0
    }

    private func isStale(_ node: LRUNode<Key, Value>, now: Date? = nil) -> Bool {
        guard let ttl = node.ttl,
              let insertTime = node.insertTime else {
            return false
        }

        let checkTime = now ?? Date()
        let age = checkTime.timeIntervalSince(insertTime)

        return age > ttl
    }

    private func calculateSize(for value: Value, key: Key) -> Int {
        if let sizeCalculation = configuration.sizeCalculation {
            return sizeCalculation(value, key)
        }
        return 1
    }

    /// Remove and return the least recently used item
    public func pop() -> (key: Key, value: Value)? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let tailNode = tail else {
            return nil
        }

        removeNode(tailNode)
        dict.removeValue(forKey: tailNode.key)

        if let size = tailNode.size {
            totalSize -= size
        }

        configuration.dispose?(tailNode.value, tailNode.key, .evict)

        return (tailNode.key, tailNode.value)
    }

    /// Iterate over all items in the cache from most to least recently used
    public func forEach(_ body: (Key, Value) throws -> Void) rethrows {
        lock.lock()
        defer { lock.unlock() }
        
        var current = head
        while let node = current {
            try body(node.key, node.value)
            current = node.next
        }
    }

    /// Get all entries as an array of tuples, ordered from most to least recently used
    public func entries() -> [(key: Key, value: Value)] {
        lock.lock()
        defer { lock.unlock() }
        
        var result: [(key: Key, value: Value)] = []
        var current = head
        while let node = current {
            result.append((node.key, node.value))
            current = node.next
        }
        return result
    }

    /// Get all keys in the cache, ordered from most to least recently used
    public func keys() -> [Key] {
        lock.lock()
        defer { lock.unlock() }
        
        var result: [Key] = []
        var current = head
        while let node = current {
            result.append(node.key)
            current = node.next
        }
        return result
    }

    /// Get all values in the cache, ordered from most to least recently used
    public func values() -> [Value] {
        lock.lock()
        defer { lock.unlock() }
        
        var result: [Value] = []
        var current = head
        while let node = current {
            result.append(node.value)
            current = node.next
        }
        return result
    }

    /// Create a debug representation of the cache
    public func dump() -> String {
        lock.lock()
        defer { lock.unlock() }
        
        var lines: [String] = []
        lines.append("LRUCache<\(Key.self), \(Value.self)> {")
        lines.append("  size: \(dict.count)")
        lines.append("  max: \(max.map { "\($0)" } ?? "nil")")
        lines.append("  calculatedSize: \(totalSize)")
        lines.append("  maxSize: \(configuration.maxSize.map { "\($0)" } ?? "nil")")
        lines.append("  items (MRU to LRU):")

        var current = head
        while let node = current {
            var details = "    \(node.key): \(node.value)"
            if node.ttl != nil, node.insertTime != nil {
                if let ttl = node.ttl, let insertTime = node.insertTime {
                    let elapsed = Date().timeIntervalSince(insertTime)
                    let remaining = Swift.max(0, ttl - elapsed)
                    details += " (TTL: \(remaining)s)"
                }
            }
            if let size = node.size {
                details += " (size: \(size))"
            }
            lines.append(details)
            current = node.next
        }

        lines.append("}")
        return lines.joined(separator: "\n")
    }
}
