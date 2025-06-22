# SwiftLRUCache

[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![CI](https://github.com/tornikegomareli/swift-lru-cache/workflows/CI/badge.svg)](https://github.com/tornikegomareli/swift-lru-cache/actions)
[![codecov](https://codecov.io/gh/tornikegomareli/swift-lru-cache/branch/main/graph/badge.svg)](https://codecov.io/gh/tornikegomareli/swift-lru-cache)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)

A high-performance, feature-complete Least Recently Used (LRU) cache implementation for Swift, inspired by the popular Node.js [lru-cache](https://github.com/isaacs/node-lru-cache) package.

## Features

- 🚀 **O(1) Performance**: All core operations (get, set, delete) maintain O(1) average time complexity
- 🔄 **True LRU Eviction**: Automatically evicts least recently used items when capacity is reached
- ⏱️ **TTL Support**: Time-to-live support with lazy expiration checking
- 📏 **Size-Based Eviction**: Configure maximum cache size based on item count or total size
- 🎯 **Flexible Configuration**: Extensive options for customizing cache behavior
- 🔧 **Disposal Callbacks**: Clean up resources when items are evicted
- 🛡️ **Type-Safe**: Full Swift type safety with generics
- 🧵 **Thread-Safe**: Safe for concurrent access (coming soon)
- 📊 **Swift 6.1**: Built with the latest Swift features

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/tornikegomareli/swift-lru-cache.git", from: "0.2.0")
]
```

## Development

### Running SwiftLint

This project includes a pre-built SwiftLint binary for code linting. To run SwiftLint:

```bash
# Run SwiftLint
./scripts/lint.sh

# Run SwiftLint with autocorrect
./scripts/lint.sh --fix
```

## Usage

### Basic Usage

```swift
import SwiftLRUCache

// Create a cache with maximum 100 items
let config = try Configuration<String, Data>(max: 100)
let cache = LRUCache<String, Data>(configuration: config)

// Set values
cache.set("key1", value: data1)
cache.set("key2", value: data2)

// Get values
if let data = cache.get("key1") {
    // Use the data
}

// Check existence
if cache.has("key2") {
    // Key exists
}

// Delete items
cache.delete("key1")

// Clear cache
cache.clear()
```

### TTL (Time To Live)

```swift
// Cache with default TTL of 5 minutes
let config = try Configuration<String, String>(max: 1000, ttl: 300)
let cache = LRUCache<String, String>(configuration: config)

// Set item with custom TTL
cache.set("session", value: "abc123", ttl: 3600) // 1 hour

// Get remaining TTL
if let remaining = cache.getRemainingTTL("session") {
    print("Session expires in \(remaining) seconds")
}

// Allow stale items
var config = try Configuration<String, String>(max: 100, ttl: 60)
config.allowStale = true
let cache = LRUCache<String, String>(configuration: config)

// Returns stale value if expired
let value = cache.get("key", options: GetOptions(allowStale: true))
```

### Size-Based Eviction

```swift
var config = try Configuration<String, Data>(maxSize: 1024 * 1024) // 1MB total
config.sizeCalculation = { data, _ in
    return data.count
}
let cache = LRUCache<String, Data>(configuration: config)

// Items will be evicted when total size exceeds 1MB
cache.set("image1", value: imageData)
```

### Disposal Callbacks

```swift
var config = try Configuration<String, FileHandle>(max: 10)
config.dispose = { handle, key, reason in
    // Clean up when items are removed
    handle.closeFile()
    print("Disposed \(key) due to \(reason)")
}
let cache = LRUCache<String, FileHandle>(configuration: config)
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