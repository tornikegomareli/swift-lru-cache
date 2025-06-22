import Foundation
@testable import SwiftLRUCache

/// Thread-safe disposal tracker for tests
final class DisposalTracker<Key: Sendable, Value: Sendable>: @unchecked Sendable {
    private var items: [(Key, Value, DisposeReason)] = []
    private let lock = NSLock()
    
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return items.count
    }
    
    func track(value: Value, key: Key, reason: DisposeReason) {
        lock.lock()
        defer { lock.unlock() }
        items.append((key, value, reason))
    }
    
    func getItem(at index: Int) -> (Key, Value, DisposeReason)? {
        lock.lock()
        defer { lock.unlock() }
        guard index < items.count else { return nil }
        return items[index]
    }
    
    func getAllItems() -> [(Key, Value, DisposeReason)] {
        lock.lock()
        defer { lock.unlock() }
        return items
    }
}