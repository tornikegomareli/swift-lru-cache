import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("TTL Tests")
struct TTLTests {
    
    @Test("Cache respects default TTL")
    func testDefaultTTL() async throws {
        let config = try Configuration<String, Int>(max: 10, ttl: 0.1) // 100ms TTL
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100)
        #expect(cache.get("key1") == 100)
        
        try await Task.sleep(nanoseconds: 150_000_000) // Sleep 150ms
        
        #expect(cache.get("key1") == nil) // Should be expired
        #expect(cache.has("key1") == false)
    }
    
    @Test("Cache can set item-specific TTL")
    func testItemSpecificTTL() async throws {
        let config = try Configuration<String, Int>(max: 10, ttl: 1) // 1 second default
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100) // Uses default TTL
        cache.set("key2", value: 200, ttl: 0.1) // 100ms TTL
        
        try await Task.sleep(nanoseconds: 150_000_000) // Sleep 150ms
        
        #expect(cache.get("key1") == 100) // Still valid
        #expect(cache.get("key2") == nil) // Expired
    }
    
    @Test("Cache returns stale items when allowStale is true")
    func testAllowStale() async throws {
        var config = try Configuration<String, Int>(max: 10, ttl: 0.1)
        config.allowStale = true
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100)
        
        try await Task.sleep(nanoseconds: 150_000_000) // Sleep 150ms
        
        let options = GetOptions(allowStale: true)
        #expect(cache.get("key1", options: options) == 100) // Returns stale value
        #expect(cache.has("key1") == false) // But has() still returns false
    }
    
    @Test("Cache updates TTL on set when updateAgeOnGet is true")
    func testUpdateAgeOnGet() async throws {
        var config = try Configuration<String, Int>(max: 10, ttl: 0.2) // 200ms
        config.updateAgeOnGet = true
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100)
        
        try await Task.sleep(nanoseconds: 100_000_000) // Sleep 100ms
        _ = cache.get("key1") // This should refresh TTL
        
        try await Task.sleep(nanoseconds: 150_000_000) // Sleep another 150ms
        
        #expect(cache.get("key1") == 100) // Should still be valid due to refresh
    }
    
    @Test("Cache respects noDeleteOnStaleGet option")
    func testNoDeleteOnStaleGet() async throws {
        var config = try Configuration<String, Int>(max: 10, ttl: 0.1)
        config.noDeleteOnStaleGet = true
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100)
        
        try await Task.sleep(nanoseconds: 150_000_000) // Sleep 150ms
        
        #expect(cache.get("key1") == nil) // Returns nil because expired
        #expect(cache.size == 1) // But item is still in cache
    }
    
    @Test("Cache calls dispose with expire reason for TTL items")
    func testDisposeOnExpire() async throws {
        var disposedItems: [(String, Int, DisposeReason)] = []
        
        var config = try Configuration<String, Int>(max: 10, ttl: 0.1)
        config.dispose = { value, key, reason in
            disposedItems.append((key, value, reason))
        }
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100)
        
        try await Task.sleep(nanoseconds: 150_000_000) // Sleep 150ms
        
        _ = cache.get("key1") // This should trigger disposal
        
        #expect(disposedItems.count == 1)
        #expect(disposedItems[0].0 == "key1")
        #expect(disposedItems[0].1 == 100)
        #expect(disposedItems[0].2 == .expire)
    }
    
    @Test("Cache purgeStale removes all expired items")
    func testPurgeStale() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100, ttl: 0.1)
        cache.set("key2", value: 200, ttl: 0.5)
        cache.set("key3", value: 300) // No TTL
        
        #expect(cache.size == 3)
        
        try await Task.sleep(nanoseconds: 150_000_000) // Sleep 150ms
        
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
        
        cache.set("key1", value: 100, ttl: 1) // 1 second TTL
        
        let remaining1 = cache.getRemainingTTL("key1")
        #expect(remaining1 != nil)
        #expect(remaining1! > 0.9)
        #expect(remaining1! <= 1.0)
        
        try await Task.sleep(nanoseconds: 500_000_000) // Sleep 500ms
        
        let remaining2 = cache.getRemainingTTL("key1")
        #expect(remaining2 != nil)
        #expect(remaining2! > 0.4)
        #expect(remaining2! < 0.6)
    }
    
    @Test("Cache respects ttlAutopurge setting")
    func testTTLAutopurge() async throws {
        var disposedItems: [(String, Int, DisposeReason)] = []
        
        var config = try Configuration<String, Int>(max: 10, ttl: 0.1)
        config.ttlAutopurge = true
        config.dispose = { value, key, reason in
            disposedItems.append((key, value, reason))
        }
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100)
        cache.set("key2", value: 200)
        
        try await Task.sleep(nanoseconds: 150_000_000) // Sleep 150ms
        
        cache.set("key3", value: 300) // This should trigger autopurge
        
        #expect(disposedItems.count >= 2) // Both expired items should be disposed
        #expect(cache.size == 1) // Only key3 should remain
    }
}