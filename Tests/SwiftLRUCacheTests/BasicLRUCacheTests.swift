import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("Basic LRU Cache Tests")
struct BasicLRUCacheTests {
    
    @Test("Cache can be initialized with configuration")
    func testCacheInitialization() throws {
        let config = try Configuration<String, Int>(max: 100)
        let cache = LRUCache<String, Int>(configuration: config)
        
        #expect(cache.size == 0)
        #expect(cache.max == 100)
    }
    
    @Test("Cache can set and get values")
    func testBasicSetAndGet() throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100)
        #expect(cache.get("key1") == 100)
        #expect(cache.size == 1)
    }
    
    @Test("Cache returns nil for missing keys")
    func testGetMissingKey() throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)
        
        #expect(cache.get("missing") == nil)
    }
    
    @Test("Cache can check if key exists")
    func testHasKey() throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100)
        #expect(cache.has("key1") == true)
        #expect(cache.has("missing") == false)
    }
    
    @Test("Cache can delete keys")
    func testDelete() throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100)
        #expect(cache.has("key1") == true)
        
        let deleted = cache.delete("key1")
        #expect(deleted == true)
        #expect(cache.has("key1") == false)
        #expect(cache.size == 0)
    }
    
    @Test("Cache evicts least recently used item when full")
    func testLRUEviction() throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("a", value: 1)
        cache.set("b", value: 2)
        cache.set("c", value: 3)
        
        #expect(cache.size == 3)
        
        cache.set("d", value: 4)
        
        #expect(cache.size == 3)
        #expect(cache.get("a") == nil) // "a" was evicted
        #expect(cache.get("b") == 2)
        #expect(cache.get("c") == 3)
        #expect(cache.get("d") == 4)
    }
    
    @Test("Cache updates LRU order on get")
    func testLRUOrderUpdateOnGet() throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("a", value: 1)
        cache.set("b", value: 2)
        cache.set("c", value: 3)
        
        _ = cache.get("a") // Access "a" to make it most recently used
        
        cache.set("d", value: 4)
        
        #expect(cache.get("a") == 1) // "a" should still be there
        #expect(cache.get("b") == nil) // "b" was evicted
        #expect(cache.get("c") == 3)
        #expect(cache.get("d") == 4)
    }
    
    @Test("Cache can clear all items")
    func testClear() throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("a", value: 1)
        cache.set("b", value: 2)
        cache.set("c", value: 3)
        
        #expect(cache.size == 3)
        
        cache.clear()
        
        #expect(cache.size == 0)
        #expect(cache.get("a") == nil)
        #expect(cache.get("b") == nil)
        #expect(cache.get("c") == nil)
    }
    
    @Test("Cache updates value for existing key")
    func testUpdateExistingKey() throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("key1", value: 100)
        cache.set("key1", value: 200)
        
        #expect(cache.get("key1") == 200)
        #expect(cache.size == 1)
    }
    
    @Test("Cache peek doesn't update LRU order")
    func testPeekDoesntUpdateOrder() throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("a", value: 1)
        cache.set("b", value: 2)
        cache.set("c", value: 3)
        
        #expect(cache.peek("a") == 1) // Peek at "a" without updating order
        
        cache.set("d", value: 4)
        
        #expect(cache.get("a") == nil) // "a" was still evicted
        #expect(cache.get("b") == 2)
        #expect(cache.get("c") == 3)
        #expect(cache.get("d") == 4)
    }
    
    @Test("Cache calls dispose handler on eviction")
    func testDisposeHandlerOnEviction() throws {
        var disposedItems: [(String, Int, DisposeReason)] = []
        
        var config = try Configuration<String, Int>(max: 2)
        config.dispose = { value, key, reason in
            disposedItems.append((key, value, reason))
        }
        
        let cache = LRUCache<String, Int>(configuration: config)
        
        cache.set("a", value: 1)
        cache.set("b", value: 2)
        cache.set("c", value: 3) // Should evict "a"
        
        #expect(disposedItems.count == 1)
        #expect(disposedItems[0].0 == "a")
        #expect(disposedItems[0].1 == 1)
        #expect(disposedItems[0].2 == .evict)
    }
}