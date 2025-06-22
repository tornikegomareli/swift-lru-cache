import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("Advanced Operations Tests")
struct AdvancedOperationsTests {

    @Test("pop removes and returns LRU item")
    func testPop() throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("a", value: 1)
        cache.set("b", value: 2)
        cache.set("c", value: 3)

        let popped = cache.pop()
        #expect(popped?.key == "a")
        #expect(popped?.value == 1)
        #expect(cache.size == 2)
        #expect(cache.has("a") == false)
    }

    @Test("pop returns nil on empty cache")
    func testPopEmptyCache() throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        let popped = cache.pop()
        #expect(popped == nil)
    }

    @Test("forEach iterates in MRU to LRU order")
    func testForEach() throws {
        let config = try Configuration<String, Int>(max: 5)
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("a", value: 1)
        cache.set("b", value: 2)
        cache.set("c", value: 3)
        _ = cache.get("a") // Make "a" most recently used

        var keys: [String] = []
        cache.forEach { key, _ in
            keys.append(key)
        }

        #expect(keys == ["a", "c", "b"])
    }

    @Test("entries returns all items in MRU to LRU order")
    func testEntries() throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("a", value: 1)
        cache.set("b", value: 2)
        cache.set("c", value: 3)

        let entries = cache.entries()
        #expect(entries.count == 3)
        #expect(entries[0].key == "c")
        #expect(entries[0].value == 3)
        #expect(entries[1].key == "b")
        #expect(entries[1].value == 2)
        #expect(entries[2].key == "a")
        #expect(entries[2].value == 1)
    }

    @Test("keys returns all keys in MRU to LRU order")
    func testKeys() throws {
        let config = try Configuration<String, Int>(max: 4)
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("a", value: 1)
        cache.set("b", value: 2)
        cache.set("c", value: 3)
        cache.set("d", value: 4)
        _ = cache.get("b") // Make "b" most recently used

        let keys = cache.keys()
        #expect(keys == ["b", "d", "c", "a"])
    }

    @Test("values returns all values in MRU to LRU order")
    func testValues() throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("a", value: 10)
        cache.set("b", value: 20)
        cache.set("c", value: 30)

        let values = cache.values()
        #expect(values == [30, 20, 10])
    }

    @Test("dump creates readable debug representation")
    func testDump() throws {
        var config = try Configuration<String, Int>(max: 3, ttl: 300)
        config.sizeCalculation = { value, _ in value }
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("a", value: 100)
        cache.set("b", value: 200)

        let dump = cache.dump()
        #expect(dump.contains("LRUCache<String, Int>"))
        #expect(dump.contains("size: 2"))
        #expect(dump.contains("max: 3"))
        #expect(dump.contains("b: 200"))
        #expect(dump.contains("a: 100"))
    }

    @Test("forEach handles throwing closures")
    func testForEachThrowing() throws {
        let config = try Configuration<String, Int>(max: 3)
        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("a", value: 1)
        cache.set("b", value: 2)

        enum TestError: Error {
            case expected
        }

        #expect(throws: TestError.expected) {
            try cache.forEach { _, value in
                if value == 2 {
                    throw TestError.expected
                }
            }
        }
    }

    @Test("pop with dispose handler")
    func testPopWithDisposeHandler() throws {
        var disposedItems: [(String, Int, DisposeReason)] = []

        var config = try Configuration<String, Int>(max: 3)
        config.dispose = { value, key, reason in
            disposedItems.append((key, value, reason))
        }

        let cache = LRUCache<String, Int>(configuration: config)

        cache.set("a", value: 1)
        cache.set("b", value: 2)

        let popped = cache.pop()
        #expect(popped?.key == "a")
        #expect(disposedItems.count == 1)
        #expect(disposedItems[0].0 == "a")
        #expect(disposedItems[0].1 == 1)
        #expect(disposedItems[0].2 == .evict)
    }

    @Test("operations on empty cache")
    func testEmptyCacheOperations() throws {
        let config = try Configuration<String, Int>(max: 10)
        let cache = LRUCache<String, Int>(configuration: config)

        #expect(cache.entries().isEmpty)
        #expect(cache.keys().isEmpty)
        #expect(cache.values().isEmpty)

        var iterationCount = 0
        cache.forEach { _, _ in
            iterationCount += 1
        }
        #expect(iterationCount == 0)
    }

    @Test("dump with TTL and size info")
    func testDumpWithMetadata() throws {
        var config = try Configuration<String, Data>(maxSize: 1024, ttl: 60)
        config.sizeCalculation = { value, _ in value.count }

        let cache = LRUCache<String, Data>(configuration: config)

        let data1 = Data(repeating: 1, count: 100)
        let data2 = Data(repeating: 2, count: 200)

        cache.set("small", value: data1)
        Thread.sleep(forTimeInterval: 0.1) // Let some time pass
        cache.set("large", value: data2)

        let dump = cache.dump()
        #expect(dump.contains("size: 2"))
        #expect(dump.contains("calculatedSize: 300"))
        #expect(dump.contains("(size: 100)"))
        #expect(dump.contains("(size: 200)"))
        #expect(dump.contains("(TTL:")) // Should show remaining TTL
    }
}