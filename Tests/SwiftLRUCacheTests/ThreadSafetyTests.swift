import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("Thread Safety Tests")
struct ThreadSafetyTests {
    
    @Test("Cache is thread-safe for concurrent reads and writes")
    func testConcurrentAccess() async throws {
        let config = try Configuration<Int, String>(max: 1000)
        let cache = LRUCache<Int, String>(configuration: config)
        
        let iterations = 100
        let concurrentTasks = 10
        
        await withTaskGroup(of: Void.self) { group in
            // Multiple writers
            for i in 0..<concurrentTasks {
                group.addTask {
                    for j in 0..<iterations {
                        let key = i * iterations + j
                        await cache.set(key, value: "value-\(key)")
                    }
                }
            }
            
            // Multiple readers
            for i in 0..<concurrentTasks {
                group.addTask {
                    for j in 0..<iterations {
                        let key = i * iterations + j
                        _ = await cache.get(key)
                    }
                }
            }
            
            // Multiple deleters
            for i in 0..<concurrentTasks/2 {
                group.addTask {
                    for j in 0..<iterations/2 {
                        let key = i * iterations + j
                        _ = await cache.delete(key)
                    }
                }
            }
        }
        
        // Verify cache is in a consistent state
        #expect(await cache.size <= 1000)
        #expect(await cache.size >= 0)
    }
    
    @Test("Cache maintains consistency under concurrent evictions")
    func testConcurrentEvictions() async throws {
        let config = try Configuration<Int, String>(max: 10)
        let cache = LRUCache<Int, String>(configuration: config)
        
        await withTaskGroup(of: Void.self) { group in
            // Fill cache beyond capacity from multiple threads
            for i in 0..<5 {
                group.addTask {
                    for j in 0..<10 {
                        await cache.set(i * 10 + j, value: "value-\(i * 10 + j)")
                    }
                }
            }
        }
        
        // Cache should never exceed max size
        #expect(await cache.size <= 10)
        
        // All operations should complete without crashes
        let entries = await cache.entries()
        let size = await cache.size
        #expect(entries.count == size)
    }
    
    @Test("Disposal callbacks are thread-safe")
    func testConcurrentDisposals() async throws {
        let disposalTracker = DisposalTracker<Int, String>()
        
        var config = try Configuration<Int, String>(max: 50)
        config.dispose = { value, key, reason in
            disposalTracker.track(value: value, key: key, reason: reason)
        }
        let cache = LRUCache<Int, String>(configuration: config)
        
        await withTaskGroup(of: Void.self) { group in
            // Add items that will trigger evictions
            for i in 0..<10 {
                group.addTask {
                    for j in 0..<20 {
                        await cache.set(i * 20 + j, value: "value-\(i * 20 + j)")
                    }
                }
            }
        }
        
        // Should have evicted items
        #expect(disposalTracker.count > 0)
        #expect(await cache.size <= 50)
    }
}