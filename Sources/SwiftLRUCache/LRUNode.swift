import Foundation

/// A node in the LRU cache's doubly-linked list.
/// Each node stores a key-value pair and maintains references to its neighbors.
final class LRUNode<Key, Value> {
    let key: Key
    var value: Value
    weak var prev: LRUNode?
    var next: LRUNode?

    var size: Int?
    var ttl: TimeInterval?
    var insertTime: Date?

    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}
