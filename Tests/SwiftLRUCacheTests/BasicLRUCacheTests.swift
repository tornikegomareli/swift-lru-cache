import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("Basic LRU Cache Tests")
struct BasicLRUCacheTests {
    @Test("Cache can be initialized with configuration")
    func testCacheInitialization() async throws {
        let config = try Configuration<String, Int>(max: 100)
        let cache = LRUCache<String, Int>(configuration: config)

        #expect(await cache.size == 0)
        #expect(cache.max == 100)
    }

    @Test("Cache can set and get values")
    func testBasicSetAndGet() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("key1", value: 100)
        #expect(await cache.get("key1") == 100)
        #expect(await cache.size == 1)
    }

    @Test("Cache returns nil for missing keys")
    func testGetMissingKey() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        #expect(await cache.get("missing") == nil)
    }

    @Test("Cache can check if key exists")
    func testHasKey() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("key1", value: 100)
        #expect(await cache.has("key1") == true)
        #expect(await cache.has("missing") == false)
    }

    @Test("Cache can delete keys")
    func testDelete() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("key1", value: 100)
        #expect(await cache.has("key1") == true)

        let deleted = await cache.delete("key1")
        #expect(deleted == true)
        #expect(await cache.has("key1") == false)
        #expect(await cache.size == 0)
    }

    @Test("Cache evicts least recently used item when full")
    func testLRUEviction() async throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("c", value: 3)

        #expect(await cache.size == 3)

        await cache.set("d", value: 4)

        #expect(await cache.size == 3)
        #expect(await cache.get("a") == nil) // "a" was evicted
        #expect(await cache.get("b") == 2)
        #expect(await cache.get("c") == 3)
        #expect(await cache.get("d") == 4)
    }

    @Test("Cache updates LRU order on get")
    func testLRUOrderUpdateOnGet() async throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("c", value: 3)

        _ = await cache.get("a") // Access "a" to make it most recently used

        await cache.set("d", value: 4)

        #expect(await cache.get("a") == 1) // "a" should still be there
        #expect(await cache.get("b") == nil) // "b" was evicted
        #expect(await cache.get("c") == 3)
        #expect(await cache.get("d") == 4)
    }

    @Test("Cache can clear all items")
    func testClear() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("c", value: 3)

        #expect(await cache.size == 3)

        await cache.clear()

        #expect(await cache.size == 0)
        #expect(await cache.get("a") == nil)
        #expect(await cache.get("b") == nil)
        #expect(await cache.get("c") == nil)
    }

    @Test("Cache updates value for existing key")
    func testUpdateExistingKey() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("key1", value: 100)
        await cache.set("key1", value: 200)

        #expect(await cache.get("key1") == 200)
        #expect(await cache.size == 1)
    }

    @Test("Cache peek doesn't update LRU order")
    func testPeekDoesntUpdateOrder() async throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("c", value: 3)

        #expect(await cache.peek("a") == 1) // Peek at "a" without updating order

        await cache.set("d", value: 4)

        #expect(await cache.get("a") == nil) // "a" was still evicted
        #expect(await cache.get("b") == 2)
        #expect(await cache.get("c") == 3)
        #expect(await cache.get("d") == 4)
    }

    @Test("Cache calls dispose handler on eviction")
    func testDisposeHandlerOnEviction() async throws {
        let disposalTracker = DisposalTracker<String, Int>()

        var config = try Configuration<String, Int>(max: 2)
        config.dispose = { value, key, reason in
            disposalTracker.track(value: value, key: key, reason: reason)
        }

        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("c", value: 3) // Should evict "a"

        #expect(disposalTracker.count == 1)
        let item = disposalTracker.getItem(at: 0)!
        #expect(item.0 == "a")
        #expect(item.1 == 1)
        #expect(item.2 == .evict)
    }
}
