import Foundation

/// A least-recently-used (LRU) cache implementation
public final class LRUCache<Key: Hashable, Value> {
    
    private let configuration: Configuration<Key, Value>
    private var dict: [Key: LRUNode<Key, Value>] = [:]
    private var head: LRUNode<Key, Value>?
    private var tail: LRUNode<Key, Value>?
    private var currentSize: Int = 0
    
    /// The maximum number of items in the cache
    public var max: Int? {
        configuration.max
    }
    
    /// The current number of items in the cache
    public var size: Int {
        dict.count
    }
    
    /// Initialize a new LRU cache with the given configuration
    public init(configuration: Configuration<Key, Value>) {
        self.configuration = configuration
    }
    
    /// Get a value from the cache
    public func get(_ key: Key) -> Value? {
        guard let node = dict[key] else {
            return nil
        }
        
        moveToHead(node)
        return node.value
    }
    
    /// Set a value in the cache
    public func set(_ key: Key, value: Value) {
        if let existingNode = dict[key] {
            existingNode.value = value
            moveToHead(existingNode)
            return
        }
        
        let newNode = LRUNode(key: key, value: value)
        dict[key] = newNode
        addToHead(newNode)
        
        if let max = configuration.max, dict.count > max {
            evictLRU()
        }
    }
    
    /// Check if a key exists in the cache
    public func has(_ key: Key) -> Bool {
        return dict[key] != nil
    }
    
    /// Delete a key from the cache
    @discardableResult
    public func delete(_ key: Key) -> Bool {
        guard let node = dict[key] else {
            return false
        }
        
        removeNode(node)
        dict.removeValue(forKey: key)
        
        configuration.dispose?(node.value, key, .delete)
        
        return true
    }
    
    /// Clear all items from the cache
    public func clear() {
        for (key, node) in dict {
            configuration.dispose?(node.value, key, .delete)
        }
        
        dict.removeAll()
        head = nil
        tail = nil
    }
    
    /// Get a value without updating its position in the LRU list
    public func peek(_ key: Key) -> Value? {
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
        
        configuration.dispose?(tailNode.value, tailNode.key, .evict)
    }
}
