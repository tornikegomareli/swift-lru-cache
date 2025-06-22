import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("TTL Tests")
struct TTLTests {

    @Test("Cache respects default TTL")
    func testDefaultTTL() async throws {
        let config = try Configuration<String, Int>(max: 10, ttl: 0.5) // 500ms TTL (increased)
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("key1", value: 100)
        #expect(cache.get("key1") == 100)

        try await Task.sleep(nanoseconds: 750_000_000) // Sleep 750ms

        #expect(cache.get("key1") == nil) // Should be expired
        #expect(cache.has("key1") == false)
    }

    @Test("Cache can set item-specific TTL")
    func testItemSpecificTTL() async throws {
        let config = try Configuration<String, Int>(max: 10, ttl: 1) // 1 second default
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("key1", value: 100) // Uses default TTL
        cache.set("key2", value: 200, ttl: 0.5) // 500ms TTL

        try await Task.sleep(nanoseconds: 750_000_000) // Sleep 750ms

        #expect(cache.get("key1") == 100) // Still valid
        #expect(cache.get("key2") == nil) // Expired
    }

    @Test("Cache returns stale items when allowStale is true")
    func testAllowStale() async throws {
        var config = try Configuration<String, Int>(max: 10, ttl: 0.5)
        config.allowStale = true
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("key1", value: 100)

        try await Task.sleep(nanoseconds: 750_000_000) // Sleep 750ms

        let options = GetOptions(allowStale: true)
        #expect(cache.get("key1", options: options) == 100) // Returns stale value
        #expect(cache.has("key1") == false) // But has() still returns false
    }

    @Test("Cache updates TTL on set when updateAgeOnGet is true")
    func testUpdateAgeOnGet() async throws {
        var config = try Configuration<String, Int>(max: 10, ttl: 2.0) // 2 seconds TTL
        config.updateAgeOnGet = true
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("key1", value: 100)

        try await Task.sleep(nanoseconds: 1_000_000_000) // Sleep 1 second
        _ = cache.get("key1") // This should refresh TTL, giving another 2 seconds

        try await Task.sleep(nanoseconds: 1_500_000_000) // Sleep 1.5 seconds (still within the refreshed 2 second TTL)

        #expect(cache.get("key1") == 100) // Should still be valid due to refresh
    }

    @Test("Cache respects noDeleteOnStaleGet option")
    func testNoDeleteOnStaleGet() async throws {
        var config = try Configuration<String, Int>(max: 10, ttl: 0.5)
        config.noDeleteOnStaleGet = true
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("key1", value: 100)

        try await Task.sleep(nanoseconds: 750_000_000) // Sleep 750ms

        #expect(cache.get("key1") == nil) // Returns nil because expired
        #expect(cache.size == 1) // But item is still in cache
    }

    @Test("Cache calls dispose with expire reason for TTL items")
    func testDisposeOnExpire() async throws {
        let disposalTracker = DisposalTracker<String, Int>()

        var config = try Configuration<String, Int>(max: 10, ttl: 0.5)
        config.dispose = { value, key, reason in
            disposalTracker.track(value: value, key: key, reason: reason)
        }
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("key1", value: 100)

        try await Task.sleep(nanoseconds: 750_000_000) // Sleep 750ms

        _ = cache.get("key1") // This should trigger disposal

        #expect(disposalTracker.count == 1)
        let item = disposalTracker.getItem(at: 0)!
        #expect(item.0 == "key1")
        #expect(item.1 == 100)
        #expect(item.2 == .expire)
    }

    @Test("Cache purgeStale removes all expired items")
    func testPurgeStale() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("key1", value: 100, ttl: 0.5)
        cache.set("key2", value: 200, ttl: 2.0)
        cache.set("key3", value: 300) // No TTL

        #expect(cache.size == 3)

        try await Task.sleep(nanoseconds: 750_000_000) // Sleep 750ms

        cache.purgeStale()

        #expect(cache.size == 2) // key1 should be purged
        #expect(cache.get("key1") == nil)
        #expect(cache.get("key2") == 200)
        #expect(cache.get("key3") == 300)
    }

    @Test("Cache getRemainingTTL returns correct value")
    func testGetRemainingTTL() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("key1", value: 100, ttl: 5) // 5 seconds TTL for more tolerance

        let remaining1 = cache.getRemainingTTL("key1")
        #expect(remaining1 != nil)
        #expect(remaining1! > 4.5) // Allow up to 500ms for execution time
        #expect(remaining1! <= 5.0)

        try await Task.sleep(nanoseconds: 2_000_000_000) // Sleep 2 seconds

        let remaining2 = cache.getRemainingTTL("key1")
        #expect(remaining2 != nil)
        #expect(remaining2! > 2.5) // Should have at least 2.5 seconds left
        #expect(remaining2! < 3.5) // But less than 3.5 seconds
    }

    @Test("Cache respects ttlAutopurge setting")
    func testTTLAutopurge() async throws {
        let disposalTracker = DisposalTracker<String, Int>()

        var config = try Configuration<String, Int>(max: 10, ttl: 0.5)
        config.ttlAutopurge = true
        config.dispose = { value, key, reason in
            disposalTracker.track(value: value, key: key, reason: reason)
        }
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("key1", value: 100)
        cache.set("key2", value: 200)

        try await Task.sleep(nanoseconds: 750_000_000) // Sleep 750ms

        cache.set("key3", value: 300) // This should trigger autopurge

        #expect(disposalTracker.count >= 2) // Both expired items should be disposed
        #expect(cache.size == 1) // Only key3 should remain
    }
}
