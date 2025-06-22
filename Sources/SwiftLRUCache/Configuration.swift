import Foundation

/// Errors that can occur during configuration
public enum ConfigurationError: Error, LocalizedError {
    case noConstraints
    case invalidMax
    case invalidMaxSize
    case invalidTTL

    public var errorDescription: String? {
        switch self {
        case .noConstraints:
            return "At least one of max, maxSize, or ttl must be specified"
        case .invalidMax:
            return "max must be a positive integer"
        case .invalidMaxSize:
            return "maxSize must be a positive integer"
        case .invalidTTL:
            return "ttl must be a positive value"
        }
    }
}

/// The reason why an item was removed from the cache
public enum DisposeReason {
    case evict
    case set
    case delete
    case expire
    case fetch
}

/// The reason why an item was added to the cache
public enum InsertReason {
    case add
    case update
    case replace
}

/// Configuration options for LRUCache
public struct Configuration<Key, Value> {
    /// Maximum number of items in cache
    public var max: Int?

    /// Maximum total size of items in cache
    public var maxSize: Int?

    /// Default time-to-live for items in milliseconds
    public var ttl: TimeInterval?

    /// Minimum time between TTL checks in milliseconds
    public var ttlResolution: TimeInterval = 1

    /// Automatically purge stale items
    public var ttlAutopurge: Bool = false

    /// Update age of items on get
    public var updateAgeOnGet: Bool = false

    /// Update age of items on has
    public var updateAgeOnHas: Bool = false

    /// Allow returning stale items
    public var allowStale: Bool = false

    /// Don't dispose items when overwriting
    public var noDisposeOnSet: Bool = false

    /// Don't update TTL when updating existing items
    public var noUpdateTTL: Bool = false

    /// Don't delete stale items on get
    public var noDeleteOnStaleGet: Bool = false

    /// Maximum size for any single item
    public var maxEntrySize: Int?

    /// Function to calculate item size
    public var sizeCalculation: ((Value, Key) -> Int)?

    /// Function called when items are removed
    public var dispose: ((Value, Key, DisposeReason) -> Void)?

    /// Function called when items are inserted
    public var onInsert: ((Value, Key, InsertReason) -> Void)?

    /// Function called after items are disposed
    public var disposeAfter: ((Value, Key, DisposeReason) -> Void)?

    public init(
        max: Int? = nil,
        maxSize: Int? = nil,
        ttl: TimeInterval? = nil
    ) throws {
        guard max != nil || maxSize != nil || ttl != nil else {
            throw ConfigurationError.noConstraints
        }

        if let max = max, max <= 0 {
            throw ConfigurationError.invalidMax
        }

        if let maxSize = maxSize, maxSize <= 0 {
            throw ConfigurationError.invalidMaxSize
        }

        if let ttl = ttl, ttl <= 0 {
            throw ConfigurationError.invalidTTL
        }

        self.max = max
        self.maxSize = maxSize
        self.ttl = ttl

        if let maxSize = maxSize {
            self.maxEntrySize = maxSize
        }
    }
}
