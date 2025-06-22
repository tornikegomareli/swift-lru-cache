# swift LRU cache

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![CI](https://github.com/tornikegomareli/swift-lru-cache/workflows/CI/badge.svg)](https://github.com/tornikegomareli/swift-lru-cache/actions)
[![codecov](https://codecov.io/gh/tornikegomareli/swift-lru-cache/branch/main/graph/badge.svg)](https://codecov.io/gh/tornikegomareli/swift-lru-cache)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)

A high-performance, thread safe, feature-complete Least Recently Used cache implementation for Swift, inspired by the popular Node.js [lru-cache](https://github.com/isaacs/node-lru-cache) package.

## Performance

SwiftLRUCache performance with **millions of operations per second**:

| Operation | Performance | Time |
|-----------|-------------|------|
| **Get** | 2.2M+ ops/sec | ~440ns |
| **Set** | 1.4M+ ops/sec | ~705ns |
| **Has** | 7.8M+ ops/sec | ~128ns |
| **Delete** | 7.8M+ ops/sec | ~127ns |

### Key Performance things

- **True O(1) complexity** for all operations
- **Sub-microsecond latency** - most operations complete in under 1μs
- **Consistent performance** across cache sizes (tested up to 1M items)
- **Efficient memory usage** with optimized data structures

[View detailed benchmarks](#benchmarks)

## Quick Start

```swift
import SwiftLRUCache

/// Simple cache with max 100 items
let cache = LRUCache<String, String>(
    configuration: try! Configuration(max: 100)
)

Task {
    /// Store value
    await cache.set("key", value: "value")
    
    /// Retrieve value
    if let value = await cache.get("key") {
        print(value)
    }
}
```

## Usage

### Basic Usage

```swift
import SwiftLRUCache

/// Create a cache with maximum 100 items
let config = try Configuration<String, Data>(max: 100)
let cache = LRUCache<String, Data>(configuration: config)

/// Set values (async)
await cache.set("key1", value: data1)
await cache.set("key2", value: data2)

/// Get values (async)
if let data = await cache.get("key1") {
    // Use the data
}

/// Check existence (async)
if await cache.has("key2") {
    // Key exists
}

/// Delete items (async)
await cache.delete("key1")

/// Clear cache (async)
await cache.clear()
```

### TTL (Time To Live)

```swift
/// Cache with default TTL of 5 minutes
let config = try Configuration<String, String>(max: 1000, ttl: 300)
let cache = LRUCache<String, String>(configuration: config)

/// Set item with custom TTL
await cache.set("session", value: "abc123", ttl: 3600) // 1 hour

/// Get remaining TTL
if let remaining = await cache.getRemainingTTL("session") {
    print("Session expires in \(remaining) seconds")
}

/// Allow stale items
var config = try Configuration<String, String>(max: 100, ttl: 60)
config.allowStale = true
let cache = LRUCache<String, String>(configuration: config)

/// Returns stale value if expired
let value = await cache.get("key", options: GetOptions(allowStale: true))
```

### Size-Based Eviction

```swift
var config = try Configuration<String, Data>(maxSize: 1024 * 1024) // 1MB total
config.sizeCalculation = { data, _ in
    return data.count
}
let cache = LRUCache<String, Data>(configuration: config)

/// Items will be evicted when total size exceeds 1MB
await cache.set("image1", value: imageData)
```

### Disposal Callbacks

```swift
var config = try Configuration<String, FileHandle>(max: 10)
config.dispose = { handle, key, reason in
    /// Clean up when items are removed
    handle.closeFile()
    print("Disposed \(key) due to \(reason)")
}
let cache = LRUCache<String, FileHandle>(configuration: config)
```

### Advanced Operations

```swift
// Pop least recently used item
if let (key, value) = await cache.pop() {
    print("Removed LRU item: \(key) = \(value)")
}

// Iterate over all items (MRU to LRU order)
await cache.forEach { key, value in
    print("\(key): \(value)")
}

// Get all entries, keys, or values
let entries = await cache.entries() // [(key: Key, value: Value)]
let keys = await cache.keys()       // [Key]
let values = await cache.values()   // [Value]

// Peek at value without updating LRU order
let value = await cache.peek("key1")

// Get cache statistics
let currentSize = await cache.size
let totalSize = await cache.calculatedSize
let maxItems = cache.max // This is not async

// Debug representation
let debugInfo = await cache.dump()
print(debugInfo)
```

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/tornikegomareli/swift-lru-cache.git", from: "0.4.0")
]
```

## Configuration Options

| Option | Type | Description |
|--------|------|-------------|
| `max` | Int? | Maximum number of items in cache |
| `maxSize` | Int? | Maximum total size of items |
| `ttl` | TimeInterval? | Default time-to-live in seconds |
| `ttlResolution` | TimeInterval | Minimum time between TTL checks (default: 1ms) |
| `ttlAutopurge` | Bool | Automatically purge stale items (default: false) |
| `updateAgeOnGet` | Bool | Refresh TTL on get (default: false) |
| `updateAgeOnHas` | Bool | Refresh TTL on has (default: false) |
| `allowStale` | Bool | Allow returning stale items (default: false) |
| `sizeCalculation` | ((Value, Key) -> Int)? | Function to calculate item size |
| `dispose` | ((Value, Key, DisposeReason) -> Void)? | Cleanup callback |
| `maxEntrySize` | Int? | Maximum size for a single item |

## Swift Concurrency & Actor Model

SwiftLRUCache uses Swift's actor model for thread safety, which means all cache operations are asynchronous. This provides several benefits:

- **Compile-time Safety**: The Swift compiler ensures thread safety
- **No Manual Locks**: Actor isolation handles all synchronization
- **Better Performance**: Non-blocking concurrent access
- **Modern Swift**: Integrates seamlessly with async/await

## Requirements

- Swift 6.0+
- macOS 14.0+ / iOS 17.0+ / tvOS 17.0+ / watchOS 10.0+ / visionOS 1.0+

## Contributing

Feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Benchmarks

Benchmarks were performed to ensure SwiftLRUCache delivers the best performance in the Swift ecosystem.

### Benchmark Environment
- **Platform**: macOS Version 15.4.1
- **Hardware**: M3 Pro
- **Swift Version**: 6.0
- **Build**: Release mode with optimizations

### Detailed Results

The benchmarks demonstrate consistent O(1) performance across different cache sizes:

| Cache Size | Get (ops/sec) | Set (ops/sec) | Has (ops/sec) | Delete (ops/sec) |
|------------|---------------|---------------|---------------|-------------------|
| 1K items   | 2.27M         | 1.42M         | 7.79M         | 7.87M            |
| 10K items  | 2.47M         | 2.08M         | 7.18M         | 7.37M            |
| 100K items | 2.27M         | 2.19M         | 4.52M         | 3.16M            |
| 1M items   | 1.40M         | 2.22M         | 2.58M         | 2.28M            |

### Advanced Operations Performance

- **TTL operations**: 2.16M ops/sec with automatic expiration checking
- **Size-based eviction**: 1.29M ops/sec with custom size calculation
- **Concurrent access**: 57K ops/sec with 10 concurrent tasks

### Running Benchmarks

To run the benchmarks yourself:

```bash
swift build -c release --product SwiftLRUCacheBenchmarks
.build/release/SwiftLRUCacheBenchmarks
```

## Acknowledgments

- Inspired by [isaacs/node-lru-cache](https://github.com/isaacs/node-lru-cache)
- Built with Swift 6.0 and Swift Testing framework
