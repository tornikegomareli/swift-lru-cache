import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("Size Tracking Tests")
struct SizeTrackingTests {
    @Test("Cache respects maxSize constraint")
    func testMaxSizeConstraint() async throws {
        var config = try Configuration<String, Data>(maxSize: 1024) // 1KB max
        config.sizeCalculation = { data, _ in
            data.count
        }
        let cache = LRUCache<String, Data>(configuration: config)

        let data1 = Data(repeating: 1, count: 400) // 400 bytes
        let data2 = Data(repeating: 2, count: 400) // 400 bytes
        let data3 = Data(repeating: 3, count: 400) // 400 bytes

        await cache.set("key1", value: data1)
        await cache.set("key2", value: data2)

        #expect(await cache.size == 2)
        #expect(await cache.calculatedSize == 800)

        await cache.set("key3", value: data3) // Should evict key1

        #expect(await cache.size == 2)
        #expect(await cache.calculatedSize == 800)
        #expect(await cache.get("key1") == nil) // Evicted
        #expect(await cache.get("key2") == data2)
        #expect(await cache.get("key3") == data3)
    }

    @Test("Cache tracks calculatedSize correctly")
    func testCalculatedSizeTracking() async throws {
        var config = try Configuration<String, String>(maxSize: 1000)
        config.sizeCalculation = { str, _ in
            str.count
        }
        let cache = LRUCache<String, String>(configuration: config)

        await cache.set("key1", value: "Hello") // 5 bytes
        #expect(await cache.calculatedSize == 5)

        await cache.set("key2", value: "World!") // 6 bytes
        #expect(await cache.calculatedSize == 11)

        await cache.delete("key1")
        #expect(await cache.calculatedSize == 6)

        await cache.clear()
        #expect(await cache.calculatedSize == 0)
    }

    @Test("Cache respects maxEntrySize")
    func testMaxEntrySize() async throws {
        var config = try Configuration<String, Data>(maxSize: 1024)
        config.maxEntrySize = 256 // Max 256 bytes per entry
        config.sizeCalculation = { data, _ in
            data.count
        }
        let cache = LRUCache<String, Data>(configuration: config)

        let smallData = Data(repeating: 1, count: 100)
        let largeData = Data(repeating: 2, count: 500) // Too large

        await cache.set("small", value: smallData)
        #expect(await cache.size == 1)
        #expect(await cache.get("small") == smallData)

        await cache.set("large", value: largeData)
        #expect(await cache.size == 1) // Large item not added
        #expect(await cache.get("large") == nil)
        #expect(await cache.get("small") == smallData) // Small item still there
    }

    @Test("Cache evicts multiple items to make space")
    func testMultipleEvictions() async throws {
        var config = try Configuration<String, Data>(maxSize: 1000)
        config.sizeCalculation = { data, _ in
            data.count
        }
        let cache = LRUCache<String, Data>(configuration: config)

        // Add multiple small items
        for i in 1...5 {
            let data = Data(repeating: UInt8(i), count: 150)
            await cache.set("key\(i)", value: data)
        }

        #expect(await cache.size == 5)
        #expect(await cache.calculatedSize == 750)

        // Add a large item that requires multiple evictions
        let largeData = Data(repeating: 9, count: 600)
        await cache.set("large", value: largeData)

        // Should have evicted key1, key2, key3 to make room
        #expect(await cache.size == 3)
        #expect(await cache.calculatedSize <= 1000)
        #expect(await cache.get("key1") == nil)
        #expect(await cache.get("key2") == nil)
        #expect(await cache.get("key3") == nil)
        #expect(await cache.get("key4") != nil)
        #expect(await cache.get("key5") != nil)
        #expect(await cache.get("large") == largeData)
    }

    @Test("Cache works with custom size calculation")
    func testCustomSizeCalculation() async throws {
        struct Person {
            let name: String
            let age: Int

            var estimatedSize: Int {
                name.count + 8 // String chars + Int size
            }
        }

        var config = try Configuration<String, Person>(maxSize: 100)
        config.sizeCalculation = { person, _ in
            person.estimatedSize
        }
        let cache = LRUCache<String, Person>(configuration: config)

        let person1 = Person(name: "Alice", age: 30) // ~13 bytes
        let person2 = Person(name: "Bob", age: 25) // ~11 bytes
        let person3 = Person(name: "Charlie", age: 35) // ~15 bytes

        await cache.set("p1", value: person1)
        await cache.set("p2", value: person2)
        await cache.set("p3", value: person3)

        #expect(await cache.size == 3)
        #expect(await cache.calculatedSize == 39)
    }

    @Test("Cache updates size on value update")
    func testSizeUpdateOnValueChange() async throws {
        var config = try Configuration<String, Data>(maxSize: 1024)
        config.sizeCalculation = { data, _ in
            data.count
        }
        let cache = LRUCache<String, Data>(configuration: config)

        let data1 = Data(repeating: 1, count: 100)
        await cache.set("key", value: data1)
        #expect(await cache.calculatedSize == 100)

        let data2 = Data(repeating: 2, count: 200)
        await cache.set("key", value: data2) // Update existing
        #expect(await cache.calculatedSize == 200) // Size updated
        #expect(await cache.size == 1) // Still one item
    }

    @Test("Cache without size calculation defaults to count-based eviction")
    func testNoSizeCalculation() async throws {
        let config = try Configuration<String, Data>(maxSize: 1_024)
        // No sizeCalculation provided
        let cache = LRUCache<String, Data>(configuration: config)

        let data1 = Data(repeating: 1, count: 100)
        let data2 = Data(repeating: 2, count: 200)

        await cache.set("key1", value: data1)
        await cache.set("key2", value: data2)

        #expect(await cache.size == 2)
        #expect(await cache.calculatedSize == 2) // Defaults to item count
    }

    @Test("Cache size-based eviction calls dispose with correct reason")
    func testSizeEvictionDispose() async throws {
        let disposalTracker = DisposalTracker<String, Data>()

        var config = try Configuration<String, Data>(maxSize: 500)
        config.sizeCalculation = { data, _ in
            data.count
        }
        config.dispose = { value, key, reason in
            disposalTracker.track(value: value, key: key, reason: reason)
        }
        let cache = LRUCache<String, Data>(configuration: config)

        let data1 = Data(repeating: 1, count: 200)
        let data2 = Data(repeating: 2, count: 200)
        let data3 = Data(repeating: 3, count: 200) // Will trigger eviction

        await cache.set("key1", value: data1)
        await cache.set("key2", value: data2)
        await cache.set("key3", value: data3)

        #expect(disposalTracker.count == 1)
        let item = disposalTracker.getItem(at: 0)!
        #expect(item.0 == "key1")
        #expect(item.2 == .evict)
    }

    @Test("Cache respects both max and maxSize constraints")
    func testBothMaxAndMaxSize() async throws {
        var config = try Configuration<String, Data>(max: 3, maxSize: 500)
        config.sizeCalculation = { data, _ in
            data.count
        }
        let cache = LRUCache<String, Data>(configuration: config)

        // Test max constraint
        for i in 1...4 {
            let data = Data(repeating: UInt8(i), count: 50)
            await cache.set("key\(i)", value: data)
        }

        #expect(await cache.size == 3) // Limited by max
        #expect(await cache.get("key1") == nil) // Evicted by count

        // Test maxSize constraint
        await cache.clear()
        let data1 = Data(repeating: 1, count: 200)
        let data2 = Data(repeating: 2, count: 200)
        let data3 = Data(repeating: 3, count: 200) // Would exceed maxSize

        await cache.set("key1", value: data1)
        await cache.set("key2", value: data2)
        await cache.set("key3", value: data3)

        #expect(await cache.size == 2) // Limited by size
        #expect(await cache.calculatedSize <= 500)
    }
}
