import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("Size Tracking Tests")
struct SizeTrackingTests {

    @Test("Cache respects maxSize constraint")
    func testMaxSizeConstraint() throws {
        var config = try Configuration<String, Data>(maxSize: 1024) // 1KB max
        config.sizeCalculation = { data, _ in
            data.count
        }
        let cache = LRUCache<String, Data>(configuration: config)

        let data1 = Data(repeating: 1, count: 400) // 400 bytes
        let data2 = Data(repeating: 2, count: 400) // 400 bytes
        let data3 = Data(repeating: 3, count: 400) // 400 bytes

        cache.set("key1", value: data1)
        cache.set("key2", value: data2)

        #expect(cache.size == 2)
        #expect(cache.calculatedSize == 800)

        cache.set("key3", value: data3) // Should evict key1

        #expect(cache.size == 2)
        #expect(cache.calculatedSize == 800)
        #expect(cache.get("key1") == nil) // Evicted
        #expect(cache.get("key2") == data2)
        #expect(cache.get("key3") == data3)
    }

    @Test("Cache tracks calculatedSize correctly")
    func testCalculatedSizeTracking() throws {
        var config = try Configuration<String, String>(maxSize: 1000)
        config.sizeCalculation = { str, _ in
            str.count
        }
        let cache = LRUCache<String, String>(configuration: config)

        cache.set("key1", value: "Hello") // 5 bytes
        #expect(cache.calculatedSize == 5)

        cache.set("key2", value: "World!") // 6 bytes
        #expect(cache.calculatedSize == 11)

        cache.delete("key1")
        #expect(cache.calculatedSize == 6)

        cache.clear()
        #expect(cache.calculatedSize == 0)
    }

    @Test("Cache respects maxEntrySize")
    func testMaxEntrySize() throws {
        var config = try Configuration<String, Data>(maxSize: 1024)
        config.maxEntrySize = 256 // Max 256 bytes per entry
        config.sizeCalculation = { data, _ in
            data.count
        }
        let cache = LRUCache<String, Data>(configuration: config)

        let smallData = Data(repeating: 1, count: 100)
        let largeData = Data(repeating: 2, count: 500) // Too large

        cache.set("small", value: smallData)
        #expect(cache.size == 1)
        #expect(cache.get("small") == smallData)

        cache.set("large", value: largeData)
        #expect(cache.size == 1) // Large item not added
        #expect(cache.get("large") == nil)
        #expect(cache.get("small") == smallData) // Small item still there
    }

    @Test("Cache evicts multiple items to make space")
    func testMultipleEvictions() throws {
        var config = try Configuration<String, Data>(maxSize: 1000)
        config.sizeCalculation = { data, _ in
            data.count
        }
        let cache = LRUCache<String, Data>(configuration: config)

        // Add multiple small items
        for i in 1...5 {
            let data = Data(repeating: UInt8(i), count: 150)
            cache.set("key\(i)", value: data)
        }

        #expect(cache.size == 5)
        #expect(cache.calculatedSize == 750)

        // Add a large item that requires multiple evictions
        let largeData = Data(repeating: 9, count: 600)
        cache.set("large", value: largeData)

        // Should have evicted key1, key2, key3 to make room
        #expect(cache.size == 3)
        #expect(cache.calculatedSize <= 1000)
        #expect(cache.get("key1") == nil)
        #expect(cache.get("key2") == nil)
        #expect(cache.get("key3") == nil)
        #expect(cache.get("key4") != nil)
        #expect(cache.get("key5") != nil)
        #expect(cache.get("large") == largeData)
    }

    @Test("Cache works with custom size calculation")
    func testCustomSizeCalculation() throws {
        struct Person {
            let name: String
            let age: Int

            var estimatedSize: Int {
                return name.count + 8 // String chars + Int size
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

        cache.set("p1", value: person1)
        cache.set("p2", value: person2)
        cache.set("p3", value: person3)

        #expect(cache.size == 3)
        #expect(cache.calculatedSize == 39)
    }

    @Test("Cache updates size on value update")
    func testSizeUpdateOnValueChange() throws {
        var config = try Configuration<String, Data>(maxSize: 1024)
        config.sizeCalculation = { data, _ in
            data.count
        }
        let cache = LRUCache<String, Data>(configuration: config)

        let data1 = Data(repeating: 1, count: 100)
        cache.set("key", value: data1)
        #expect(cache.calculatedSize == 100)

        let data2 = Data(repeating: 2, count: 200)
        cache.set("key", value: data2) // Update existing
        #expect(cache.calculatedSize == 200) // Size updated
        #expect(cache.size == 1) // Still one item
    }

    @Test("Cache without size calculation defaults to count-based eviction")
    func testNoSizeCalculation() throws {
        let config = try Configuration<String, Data>(maxSize: 1024)
        // No sizeCalculation provided
        let cache = LRUCache<String, Data>(configuration: config)

        let data1 = Data(repeating: 1, count: 100)
        let data2 = Data(repeating: 2, count: 200)

        cache.set("key1", value: data1)
        cache.set("key2", value: data2)

        #expect(cache.size == 2)
        #expect(cache.calculatedSize == 2) // Defaults to item count
    }

    @Test("Cache size-based eviction calls dispose with correct reason")
    func testSizeEvictionDispose() throws {
        var disposedItems: [(String, Data, DisposeReason)] = []

        var config = try Configuration<String, Data>(maxSize: 500)
        config.sizeCalculation = { data, _ in
            data.count
        }
        config.dispose = { value, key, reason in
            disposedItems.append((key, value, reason))
        }
        let cache = LRUCache<String, Data>(configuration: config)

        let data1 = Data(repeating: 1, count: 200)
        let data2 = Data(repeating: 2, count: 200)
        let data3 = Data(repeating: 3, count: 200) // Will trigger eviction

        cache.set("key1", value: data1)
        cache.set("key2", value: data2)
        cache.set("key3", value: data3)

        #expect(disposedItems.count == 1)
        #expect(disposedItems[0].0 == "key1")
        #expect(disposedItems[0].2 == .evict)
    }

    @Test("Cache respects both max and maxSize constraints")
    func testBothMaxAndMaxSize() throws {
        var config = try Configuration<String, Data>(max: 3, maxSize: 500)
        config.sizeCalculation = { data, _ in
            data.count
        }
        let cache = LRUCache<String, Data>(configuration: config)

        // Test max constraint
        for i in 1...4 {
            let data = Data(repeating: UInt8(i), count: 50)
            cache.set("key\(i)", value: data)
        }

        #expect(cache.size == 3) // Limited by max
        #expect(cache.get("key1") == nil) // Evicted by count

        // Test maxSize constraint
        cache.clear()
        let data1 = Data(repeating: 1, count: 200)
        let data2 = Data(repeating: 2, count: 200)
        let data3 = Data(repeating: 3, count: 200) // Would exceed maxSize

        cache.set("key1", value: data1)
        cache.set("key2", value: data2)
        cache.set("key3", value: data3)

        #expect(cache.size == 2) // Limited by size
        #expect(cache.calculatedSize <= 500)
    }
}