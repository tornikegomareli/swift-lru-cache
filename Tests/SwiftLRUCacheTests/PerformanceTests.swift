import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("Performance Tests")
struct PerformanceTests {
    
    /// Measure the average time for an operation across multiple runs
    private func measureAverageTime(iterations: Int, operation: () async throws -> Void) async rethrows -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            try await operation()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        return (endTime - startTime) / Double(iterations)
    }
    
    @Test("Cache get operation is O(1)")
    func testGetIsO1() async throws {
        // Test with different cache sizes to ensure O(1) behavior
        let sizes = [1000, 10_000, 100_000]
        var timings: [Int: TimeInterval] = [:]
        
        for size in sizes {
            let config = try Configuration<Int, String>(max: size * 2)
            let cache = LRUCache<Int, String>(configuration: config)
            
            // Fill cache to the test size
            for i in 0..<size {
                await cache.set(i, value: "value-\(i)")
            }
            
            // Measure get operations
            let avgTime = try await measureAverageTime(iterations: 10_000) {
                _ = await cache.get(Int.random(in: 0..<size))
            }
            
            timings[size] = avgTime
            print("Get operation for \(size) items: \(avgTime * 1_000_000) microseconds")
        }
        
        // Verify O(1): time should not increase significantly with size
        // Allow up to 2x variance (due to system factors)
        if let time1k = timings[1000], let time100k = timings[100_000] {
            let ratio = time100k / time1k
            #expect(ratio < 2.0, "Get operation time increased by \(ratio)x, expected O(1)")
        }
    }
    
    @Test("Cache set operation is O(1)")
    func testSetIsO1() async throws {
        let sizes = [1000, 10_000, 100_000]
        var timings: [Int: TimeInterval] = [:]
        
        for size in sizes {
            let config = try Configuration<Int, String>(max: size * 2)
            let cache = LRUCache<Int, String>(configuration: config)
            
            // Pre-fill cache halfway
            for i in 0..<size/2 {
                await cache.set(i, value: "value-\(i)")
            }
            
            // Measure set operations
            let avgTime = try await measureAverageTime(iterations: 10_000) {
                let key = Int.random(in: size..<size*2)
                await cache.set(key, value: "value-\(key)")
            }
            
            timings[size] = avgTime
            print("Set operation for \(size) items: \(avgTime * 1_000_000) microseconds")
        }
        
        // Verify O(1)
        if let time1k = timings[1000], let time100k = timings[100_000] {
            let ratio = time100k / time1k
            #expect(ratio < 2.0, "Set operation time increased by \(ratio)x, expected O(1)")
        }
    }
    
    @Test("Cache delete operation is O(1)")
    func testDeleteIsO1() async throws {
        let sizes = [1000, 10_000, 100_000]
        var timings: [Int: TimeInterval] = [:]
        
        for size in sizes {
            let config = try Configuration<Int, String>(max: size * 2)
            let cache = LRUCache<Int, String>(configuration: config)
            
            // Fill cache
            for i in 0..<size {
                await cache.set(i, value: "value-\(i)")
            }
            
            // Create a list of keys to delete
            let keysToDelete = (0..<1000).map { _ in Int.random(in: 0..<size) }
            
            // Measure delete operations
            let avgTime = try await measureAverageTime(iterations: 1000) {
                let key = keysToDelete[Int.random(in: 0..<keysToDelete.count)]
                _ = await cache.delete(key)
            }
            
            timings[size] = avgTime
            print("Delete operation for \(size) items: \(avgTime * 1_000_000) microseconds")
        }
        
        // Verify O(1)
        if let time1k = timings[1000], let time100k = timings[100_000] {
            let ratio = time100k / time1k
            #expect(ratio < 2.0, "Delete operation time increased by \(ratio)x, expected O(1)")
        }
    }
    
    @Test("Cache has operation is O(1)")
    func testHasIsO1() async throws {
        let sizes = [1000, 10_000, 100_000]
        var timings: [Int: TimeInterval] = [:]
        
        for size in sizes {
            let config = try Configuration<Int, String>(max: size * 2)
            let cache = LRUCache<Int, String>(configuration: config)
            
            // Fill cache
            for i in 0..<size {
                await cache.set(i, value: "value-\(i)")
            }
            
            // Measure has operations
            let avgTime = try await measureAverageTime(iterations: 10_000) {
                _ = await cache.has(Int.random(in: 0..<size))
            }
            
            timings[size] = avgTime
            print("Has operation for \(size) items: \(avgTime * 1_000_000) microseconds")
        }
        
        // Verify O(1)
        if let time1k = timings[1000], let time100k = timings[100_000] {
            let ratio = time100k / time1k
            #expect(ratio < 2.0, "Has operation time increased by \(ratio)x, expected O(1)")
        }
    }
    
    @Test("LRU eviction maintains O(1) for set operations")
    func testLRUEvictionIsO1() async throws {
        // Test that eviction doesn't degrade performance
        let sizes = [1000, 10_000, 50_000]
        var timings: [Int: TimeInterval] = [:]
        
        for size in sizes {
            // Cache is exactly at capacity
            let config = try Configuration<Int, String>(max: size)
            let cache = LRUCache<Int, String>(configuration: config)
            
            // Fill cache to capacity
            for i in 0..<size {
                await cache.set(i, value: "value-\(i)")
            }
            
            // Measure set operations that cause evictions
            let avgTime = try await measureAverageTime(iterations: 5000) {
                let key = Int.random(in: size..<size*2)
                await cache.set(key, value: "value-\(key)")
            }
            
            timings[size] = avgTime
            print("Set with eviction for \(size) items: \(avgTime * 1_000_000) microseconds")
        }
        
        // Verify O(1) even with evictions
        if let time1k = timings[1000], let time50k = timings[50_000] {
            let ratio = time50k / time1k
            #expect(ratio < 2.5, "Set with eviction time increased by \(ratio)x, expected O(1)")
        }
    }
    
    @Test("Verify dictionary and linked list are properly maintained")
    func testDataStructureIntegrity() async throws {
        // This test ensures our O(1) operations are actually using
        // both the dictionary and linked list correctly
        
        let config = try Configuration<String, Int>(max: 5)
        let cache = LRUCache<String, Int>(configuration: config)
        
        // Add items
        await cache.set("a", value: 1)
        await cache.set("b", value: 2)
        await cache.set("c", value: 3)
        await cache.set("d", value: 4)
        await cache.set("e", value: 5)
        
        // Access 'a' to make it MRU
        _ = await cache.get("a")
        
        // Add new item, should evict 'b' (LRU)
        await cache.set("f", value: 6)
        
        // Verify correct eviction
        #expect(await cache.has("a") == true)
        #expect(await cache.has("b") == false)
        #expect(await cache.has("c") == true)
        
        // Verify order
        let keys = await cache.keys()
        #expect(keys == ["f", "a", "e", "d", "c"])
    }
    
    @Test("Measure operation time distribution")
    func testOperationTimeDistribution() async throws {
        // This test checks that operations have consistent timing
        // which is characteristic of O(1) operations
        
        let config = try Configuration<Int, String>(max: 100_000)
        let cache = LRUCache<Int, String>(configuration: config)
        
        // Fill cache
        for i in 0..<50_000 {
            await cache.set(i, value: "value-\(i)")
        }
        
        // Measure individual operation times
        var getTimes: [TimeInterval] = []
        
        for _ in 0..<1000 {
            let key = Int.random(in: 0..<50_000)
            let start = CFAbsoluteTimeGetCurrent()
            _ = await cache.get(key)
            let end = CFAbsoluteTimeGetCurrent()
            getTimes.append(end - start)
        }
        
        // Calculate statistics
        let avgTime = getTimes.reduce(0, +) / Double(getTimes.count)
        let sortedTimes = getTimes.sorted()
        let medianTime = sortedTimes[sortedTimes.count / 2]
        let p95Time = sortedTimes[Int(Double(sortedTimes.count) * 0.95)]
        let p99Time = sortedTimes[Int(Double(sortedTimes.count) * 0.99)]
        
        print("Get operation time distribution:")
        print("  Average: \(avgTime * 1_000_000) μs")
        print("  Median: \(medianTime * 1_000_000) μs")
        print("  95th percentile: \(p95Time * 1_000_000) μs")
        print("  99th percentile: \(p99Time * 1_000_000) μs")
        
        // For O(1) operations, the 99th percentile should not be
        // significantly higher than the median (allowing 10x for system variance)
        let ratio = p99Time / medianTime
        #expect(ratio < 10.0, "High variance in operation times (ratio: \(ratio))")
    }
}