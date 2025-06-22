import Foundation

/// Options for the get operation
public struct GetOptions {
    public var allowStale: Bool?
    public var updateAgeOnGet: Bool?
    public var noDeleteOnStaleGet: Bool?

    public init(
        allowStale: Bool? = nil,
        updateAgeOnGet: Bool? = nil,
        noDeleteOnStaleGet: Bool? = nil
    ) {
        self.allowStale = allowStale
        self.updateAgeOnGet = updateAgeOnGet
        self.noDeleteOnStaleGet = noDeleteOnStaleGet
    }
}

/// Options for the set operation
public struct SetOptions {
    public var ttl: TimeInterval?
    public var noUpdateTTL: Bool?
    public var size: Int?
    public var noDisposeOnSet: Bool?

    public init(
        ttl: TimeInterval? = nil,
        noUpdateTTL: Bool? = nil,
        size: Int? = nil,
        noDisposeOnSet: Bool? = nil
    ) {
        self.ttl = ttl
        self.noUpdateTTL = noUpdateTTL
        self.size = size
        self.noDisposeOnSet = noDisposeOnSet
    }
}