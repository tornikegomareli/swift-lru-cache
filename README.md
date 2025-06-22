# SwiftLRUCache

[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![CI](https://github.com/tornikegomareli/swift-lru-cache/workflows/CI/badge.svg)](https://github.com/tornikegomareli/swift-lru-cache/actions)
[![codecov](https://codecov.io/gh/tornikegomareli/swift-lru-cache/branch/main/graph/badge.svg)](https://codecov.io/gh/tornikegomareli/swift-lru-cache)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)

A high-performance, feature-complete Least Recently Used (LRU) cache implementation for Swift, inspired by the popular Node.js [lru-cache](https://github.com/isaacs/node-lru-cache) package.

## Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic Usage](#basic-usage)
  - [TTL (Time To Live)](#ttl-time-to-live)
  - [Size-Based Eviction](#size-based-eviction)
  - [Disposal Callbacks](#disposal-callbacks)
  - [Advanced Operations](#advanced-operations)
  - [Complete Example: Session Cache](#complete-example-session-cache)
- [Configuration Options](#configuration-options)
- [Swift Concurrency & Actor Model](#swift-concurrency--actor-model)
- [Performance](#performance)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

## Quick Start

```swift
import SwiftLRUCache

// Simple cache with max 100 items
let cache = LRUCache<String, String>(
    configuration: try! Configuration(max: 100)
)

// Use in async context
Task {
    // Store value
    await cache.set("key", value: "value")
    
    // Retrieve value
    if let value = await cache.get("key") {
        print(value) // "value"
    }
}
```

## Features

- 🚀 **O(1) Performance**: All core operations (get, set, delete) maintain O(1) average time complexity
- 🔄 **True LRU Eviction**: Automatically evicts least recently used items when capacity is reached
- ⏱️ **TTL Support**: Time-to-live support with per-item expiration, stale-while-revalidate, and auto-purge options
- 📏 **Size-Based Eviction**: Configure maximum cache size based on item count, total memory size, or both
- 🎯 **Flexible Configuration**: Extensive options including updateAgeOnGet, allowStale, noDeleteOnStaleGet, and more
- 🔧 **Disposal Callbacks**: Clean up resources when items are evicted, expired, or deleted with reason tracking
- 🛡️ **Type-Safe**: Full Swift type safety with generics and Sendable conformance
- 🧵 **Thread-Safe**: Safe for concurrent access using Swift's actor model with compile-time guarantees
- 📊 **Swift 6.1**: Built with the latest Swift features including strict concurrency checking
- 🔍 **Debugging**: Built-in dump() method for cache inspection and statistics

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/tornikegomareli/swift-lru-cache.git", from: "0.4.0")
]
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

### Complete Example: Session Cache

Here's a comprehensive example showing all features working together:

```swift
import SwiftLRUCache
import Foundation

// Define a session struct
struct UserSession {
    let userId: String
    let token: String
    let loginTime: Date
    
    var dataSize: Int {
        userId.count + token.count + 32 // Approximate size
    }
}

// Configure cache with multiple constraints
var config = try Configuration<String, UserSession>(
    max: 1000,           // Maximum 1000 sessions
    maxSize: 1_048_576,  // Maximum 1MB total memory
    ttl: 3600            // 1 hour default TTL
)

// Set up size calculation
config.sizeCalculation = { session, _ in
    session.dataSize
}

// Set up TTL auto-purge for expired sessions
config.ttlAutopurge = true

// Update session TTL when accessed
config.updateAgeOnGet = true

// Handle session cleanup
config.dispose = { session, sessionId, reason in
    switch reason {
    case .expire:
        print("Session \(sessionId) expired")
        // Log expired session
    case .evict:
        print("Session \(sessionId) evicted due to capacity")
        // Save to persistent storage if needed
    case .delete:
        print("Session \(sessionId) manually deleted")
        // Clean up resources
    default:
        break
    }
}

// Create the cache
let sessionCache = LRUCache<String, UserSession>(configuration: config)

// Use in an async context
Task {
    // Add a new session
    let session = UserSession(
        userId: "user123",
        token: "abc-def-ghi",
        loginTime: Date()
    )
    
    await sessionCache.set("session-001", value: session)
    
    // Add premium user session with longer TTL
    let premiumSession = UserSession(
        userId: "premium456",
        token: "xyz-uvw-rst",
        loginTime: Date()
    )
    
    await sessionCache.set("session-002", value: premiumSession, ttl: 7200) // 2 hours
    
    // Check if session exists
    if await sessionCache.has("session-001") {
        // Get session (this refreshes TTL due to updateAgeOnGet)
        if let activeSession = await sessionCache.get("session-001") {
            print("Active session for user: \(activeSession.userId)")
        }
    }
    
    // Check remaining time
    if let ttl = await sessionCache.getRemainingTTL("session-002") {
        print("Premium session expires in \(Int(ttl)) seconds")
    }
    
    // Get all active sessions
    let activeSessions = await sessionCache.entries()
    print("Active sessions: \(activeSessions.count)")
    
    // Remove expired sessions manually
    await sessionCache.purgeStale()
    
    // Get cache stats
    let stats = """
    Cache Statistics:
    - Current sessions: \(await sessionCache.size)
    - Memory used: \(await sessionCache.calculatedSize) bytes
    - Max capacity: \(sessionCache.max ?? 0) sessions
    """
    print(stats)
    
    // Debug output
    print(await sessionCache.dump())
}
```

### Error Handling Example

```swift
// Configuration validation
do {
    // This will throw - no constraints specified
    let invalidConfig = try Configuration<String, String>()
} catch ConfigurationError.noConstraints {
    print("Error: Must specify at least one constraint (max, maxSize, or ttl)")
}

// Handle size constraints
var sizeConfig = try Configuration<String, Data>(maxSize: 1024)
sizeConfig.maxEntrySize = 512  // No single item larger than 512 bytes
sizeConfig.sizeCalculation = { data, _ in data.count }

let dataCache = LRUCache<String, Data>(configuration: sizeConfig)

Task {
    let smallData = Data(repeating: 0, count: 256)
    let largeData = Data(repeating: 1, count: 768)
    
    // This will succeed
    await dataCache.set("small", value: smallData)
    
    // This will be rejected due to maxEntrySize
    await dataCache.set("large", value: largeData)
    
    // Verify
    print("Small data cached: \(await dataCache.has("small"))")  // true
    print("Large data cached: \(await dataCache.has("large"))")  // false
}
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

### Using with SwiftUI

```swift
@MainActor
class CacheViewModel: ObservableObject {
    private let imageCache: LRUCache<String, UIImage>
    
    init() throws {
        var config = try Configuration<String, UIImage>(
            max: 100,
            maxSize: 50 * 1024 * 1024 // 50MB
        )
        config.sizeCalculation = { image, _ in
            Int(image.size.width * image.size.height * 4) // Approximate bytes
        }
        self.imageCache = LRUCache(configuration: config)
    }
    
    func loadImage(url: String) async -> UIImage? {
        // Check cache first
        if let cachedImage = await imageCache.get(url) {
            return cachedImage
        }
        
        // Load from network
        guard let image = await downloadImage(from: url) else {
            return nil
        }
        
        // Cache for future use
        await imageCache.set(url, value: image)
        return image
    }
}
```

### Using with Structured Concurrency

```swift
func processBatch(items: [String]) async {
    let cache = LRUCache<String, ProcessedData>(
        configuration: try! Configuration(max: 1000)
    )
    
    // Process items concurrently
    await withTaskGroup(of: Void.self) { group in
        for item in items {
            group.addTask {
                let processed = await self.processItem(item)
                await cache.set(item, value: processed)
            }
        }
    }
    
    // All items are now cached
    print("Cached \(await cache.size) items")
}
```

## Performance

The cache uses a combination of a Swift Dictionary and a doubly-linked list to achieve O(1) performance for all core operations:

- **Get**: O(1) - Direct hash table lookup + move to head
- **Set**: O(1) - Hash table insertion + add to head
- **Delete**: O(1) - Hash table deletion + node removal
- **Has**: O(1) - Hash table lookup

## Requirements

- Swift 6.1+
- macOS 14.0+ / iOS 17.0+ / tvOS 17.0+ / watchOS 10.0+ / visionOS 1.0+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [isaacs/node-lru-cache](https://github.com/isaacs/node-lru-cache)
- Built with Swift 6.1 and Swift Testing framework
