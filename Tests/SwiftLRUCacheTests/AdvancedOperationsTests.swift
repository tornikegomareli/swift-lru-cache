import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("Advanced Operations Tests")
struct AdvancedOperationsTests {
    @Test("pop removes and returns LRU item")
    func testPop() async throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("c", value: 3)

        let popped = await cache.pop()
        #expect(popped?.key == "a")
        #expect(popped?.value == 1)
        #expect(await cache.size == 2)
        #expect(await cache.has("a") == false)
    }

    @Test("pop returns nil on empty cache")
    func testPopEmptyCache() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        let popped = await cache.pop()
        #expect(popped == nil)
    }

    @Test("forEach iterates in MRU to LRU order")
    func testForEach() async throws {
        let config = try Configuration<String, Int>(max: 5)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("c", value: 3)
        _ = await cache.get("a") // Make "a" most recently used

        var keys: [String] = []
        await cache.forEach { key, _ in
            keys.append(key)
        }

        #expect(keys == ["a", "c", "b"])
    }

    @Test("entries returns all items in MRU to LRU order")
    func testEntries() async throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("c", value: 3)

        let entries = await cache.entries()
        #expect(entries.count == 3)
        #expect(entries[0].key == "c")
        #expect(entries[0].value == 3)
        #expect(entries[1].key == "b")
        #expect(entries[1].value == 2)
        #expect(entries[2].key == "a")
        #expect(entries[2].value == 1)
    }

    @Test("keys returns all keys in MRU to LRU order")
    func testKeys() async throws {
        let config = try Configuration<String, Int>(max: 4)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("c", value: 3)
        await cache.set("d", value: 4)
        _ = await cache.get("b") // Make "b" most recently used

        let keys = await cache.keys()
        #expect(keys == ["b", "d", "c", "a"])
    }

    @Test("values returns all values in MRU to LRU order")
    func testValues() async throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 10)
        await cache.set("b", value: 20)
        await cache.set("c", value: 30)

        let values = await cache.values()
        #expect(values == [30, 20, 10])
    }

    @Test("dump creates readable debug representation")
    func testDump() async throws {
        var config = try Configuration<String, Int>(max: 3, ttl: 300)
        config.sizeCalculation = { value, _ in value }
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 100)
        await cache.set("b", value: 200)

        let dump = await cache.dump()
        #expect(dump.contains("LRUCache<String, Int>"))
        #expect(dump.contains("size: 2"))
        #expect(dump.contains("max: 3"))
        #expect(dump.contains("b: 200"))
        #expect(dump.contains("a: 100"))
    }

    @Test("forEach handles throwing closures")
    func testForEachThrowing() async throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)

        enum TestError: Error {
            case expected
        }

        await #expect(throws: TestError.expected) {
            try await cache.forEach { _, value in
                if value == 2 {
                    throw TestError.expected
                }
            }
        }
    }

    @Test("pop with dispose handler")
    func testPopWithDisposeHandler() async throws {
        let disposalTracker = DisposalTracker<String, Int>()

        var config = try Configuration<String, Int>(max: 3)
        config.dispose = { value, key, reason in
            disposalTracker.track(value: value, key: key, reason: reason)
        }

        let cache = LRUCache<String, Int>(configuration: config)

        await cache.set("a", value: 1)
        await cache.set("b", value: 2)

        let popped = await cache.pop()
        #expect(popped?.key == "a")
        #expect(disposalTracker.count == 1)
        let item = disposalTracker.getItem(at: 0)!
        #expect(item.0 == "a")
        #expect(item.1 == 1)
        #expect(item.2 == .evict)
    }

    @Test("operations on empty cache")
    func testEmptyCacheOperations() async throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        #expect(await cache.entries().isEmpty)
        #expect(await cache.keys().isEmpty)
        #expect(await cache.values().isEmpty)

        var iterationCount = 0
        await cache.forEach { _, _ in
            iterationCount += 1
        }
        #expect(iterationCount == 0)
    }

    @Test("dump with TTL and size info")
    func testDumpWithMetadata() async throws {
        var config = try Configuration<String, Data>(maxSize: 1_024, ttl: 60)
        config.sizeCalculation = { value, _ in value.count }

        let cache = LRUCache<String, Data>(configuration: config)

        let data1 = Data(repeating: 1, count: 100)
        let data2 = Data(repeating: 2, count: 200)

        await cache.set("small", value: data1)
        try await Task.sleep(nanoseconds: 100_000_000) // Let some time pass (100ms)
        await cache.set("large", value: data2)

        let dump = await cache.dump()
        #expect(dump.contains("size: 2"))
        #expect(dump.contains("calculatedSize: 300"))
        #expect(dump.contains("(size: 100)"))
        #expect(dump.contains("(size: 200)"))
        #expect(dump.contains("(TTL:")) // Should show remaining TTL
    }
}
