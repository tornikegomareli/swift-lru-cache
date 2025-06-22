# Swift LRU Cache - Planning Document

## Project Overview

This project aims to create a Swift implementation of the popular Node.js lru-cache package. The implementation will provide a least-recently-used (LRU) cache with O(1) average time complexity for core operations, leveraging Swift 6.1's latest features including improved concurrency support and memory safety guarantees.

The cache will maintain feature parity with the Node.js version while being idiomatic to Swift, including:
- Configurable maximum cache size (by count or total size)
- TTL (Time To Live) support with automatic expiration
- Size-based eviction with custom size calculators
- Disposal callbacks for cleanup operations
- Performance optimizations through lazy evaluation and minimal allocations

## Architecture

### Core Components

1. **LRUCache Class** - The main cache implementation
   - Generic over Key and Value types
   - Uses a combination of Dictionary and doubly-linked list
   - Thread-safe operations using Swift's actor model or locks

2. **Node Structure** - Internal linked list node
   - Holds key-value pairs
   - Forward and backward pointers
   - TTL and size metadata

3. **Configuration** - Cache options and settings
   - `max`: Maximum number of items
   - `maxSize`: Maximum total size
   - `ttl`: Default time-to-live
   - `sizeCalculation`: Custom size calculator closure
   - `dispose`: Cleanup callback
   - `onInsert`: Insertion callback

4. **TTL Manager** - Handles time-based expiration
   - Lazy expiration checking
   - Optional TTL refresh on access
   - Configurable TTL resolution

5. **Size Tracker** - Manages size-based eviction
   - Tracks individual item sizes
   - Maintains total cache size
   - Enforces maxEntrySize limits

### Data Model

The cache uses a hybrid data structure:

```
Dictionary<Key, Node>  // O(1) key lookup
+
Doubly Linked List     // O(1) LRU ordering
```

Where Node contains:
- key: Key
- value: Value
- prev: Node?
- next: Node?
- size: Int?
- ttl: TimeInterval?
- insertTime: Date?

## API Endpoints

### Core Methods
- `init(options:)` - Initialize cache with configuration
- `get(_:options:)` - Retrieve value by key
- `set(_:value:options:)` - Store key-value pair
- `has(_:)` - Check key existence
- `delete(_:)` - Remove specific key
- `clear()` - Remove all entries
- `peek(_:)` - Get without updating recency

### Advanced Methods
- `fetch(_:options:)` - Async fetch with stale-while-revalidate
- `memo(_:options:compute:)` - Memoization helper
- `forEach(_:)` - Iterate over entries
- `purgeStale()` - Remove expired entries
- `getRemainingTTL(_:)` - Get time until expiration
- `entries()` - Get all key-value pairs
- `keys()` - Get all keys
- `values()` - Get all values

### Properties
- `size: Int` - Current number of items
- `calculatedSize: Int` - Total size of items
- `max: Int` - Maximum item count
- `maxSize: Int` - Maximum total size

## Technology Stack

- **Language**: Swift 6.1
- **Platform**: macOS, iOS, tvOS, watchOS, Linux
- **Package Manager**: Swift Package Manager (SPM)
- **Testing Framework**: Swift Testing (new XCTest replacement)
- **Concurrency**: Swift Concurrency (async/await, actors)
- **Documentation**: DocC format

## Project Structure

```
swift-lrucache/
├── Package.swift
├── README.md
├── PLANNING.md
├── TASK.md
├── CLAUDE.md
├── Sources/
│   └── SwiftLRUCache/
│       ├── LRUCache.swift         // Main cache implementation
│       ├── Node.swift             // Linked list node
│       ├── Configuration.swift    // Cache options
│       ├── TTLManager.swift       // TTL handling
│       ├── SizeTracker.swift      // Size calculations
│       ├── CacheError.swift       // Error types
│       └── Extensions/            // Swift extensions
├── Tests/
│   └── SwiftLRUCacheTests/
│       ├── LRUCacheTests.swift    // Core functionality tests
│       ├── TTLTests.swift         // TTL-specific tests
│       ├── SizeTests.swift        // Size tracking tests
│       ├── PerformanceTests.swift // Benchmark tests
│       └── ConcurrencyTests.swift // Thread safety tests
└── Benchmarks/
    └── LRUCacheBenchmarks/
        └── Benchmarks.swift       // Performance benchmarks

```

## Testing Strategy

### Unit Tests
- Test all public API methods
- Edge cases (empty cache, single item, full cache)
- TTL expiration scenarios
- Size-based eviction
- Disposal callback invocation
- Error handling

### Integration Tests
- Multi-threaded access patterns
- Memory pressure scenarios
- Large dataset handling
- Real-world usage patterns

### Performance Tests
- Benchmark against other Swift cache implementations
- Measure operation complexity (should be O(1))
- Memory usage profiling
- Stress testing with millions of operations

### Test Coverage Goals
- Minimum 90% code coverage
- 100% coverage of public API
- All edge cases documented and tested

## Development Commands

```bash
# Build the package
swift build

# Run tests
swift test

# Run tests with coverage
swift test --enable-code-coverage

# Generate documentation
swift package generate-documentation

# Run benchmarks
swift run -c release LRUCacheBenchmarks

# Format code
swift-format -i -r Sources/ Tests/

# Lint code
swift-format lint -r Sources/ Tests/

# Clean build artifacts
swift package clean

# Update dependencies
swift package update
```

## Environment Setup

### Prerequisites
- Swift 6.1 or later
- Xcode 16.0+ (for macOS development)
- Swift toolchain for Linux (if developing on Linux)

### Development Setup
1. Clone the repository
2. Open Package.swift in Xcode or your preferred editor
3. Build the package to verify setup
4. Run tests to ensure everything works

### Recommended Tools
- **IDE**: Xcode 16+ or VS Code with Swift extension
- **Swift Format**: For consistent code style
- **SwiftLint**: For additional linting rules
- **Git hooks**: Pre-commit formatting and linting

## Development Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Keep functions small and focused
- Prefer value types over reference types where appropriate
- Use Swift's type system to prevent errors

### Performance Considerations
- Maintain O(1) complexity for core operations
- Minimize allocations in hot paths
- Use lazy evaluation where beneficial
- Profile before optimizing
- Consider memory vs speed tradeoffs

### Concurrency
- Use Swift's actor model for thread safety
- Avoid locks where possible
- Test concurrent access thoroughly
- Document thread safety guarantees

### Error Handling
- Use Swift's error handling for recoverable errors
- Provide clear error messages
- Use preconditions for programmer errors
- Never crash on user input

### Documentation
- Document all public APIs with DocC comments
- Include usage examples in documentation
- Explain complex algorithms with inline comments
- Keep README up to date

## Security Considerations

### Input Validation
- Validate configuration parameters
- Prevent integer overflow in size calculations
- Handle malformed input gracefully

### Memory Safety
- Prevent retain cycles in callbacks
- Use weak references where appropriate
- Implement proper cleanup in deinit
- Guard against unbounded growth

### Thread Safety
- Ensure all operations are thread-safe
- Document any threading requirements
- Use appropriate synchronization primitives
- Test for race conditions

### Resource Limits
- Enforce maximum cache size limits
- Prevent DoS through excessive allocations
- Implement backpressure mechanisms
- Monitor memory usage

## Future Considerations

### Version 2.0 Features
- **Persistence**: Save/restore cache to disk
- **Distributed Caching**: Multi-node cache support
- **Statistics**: Detailed cache hit/miss metrics
- **Compression**: Optional value compression
- **Encryption**: At-rest encryption support

### Performance Enhancements
- Custom allocator for node objects
- SIMD operations for bulk operations
- Memory-mapped file backing
- Zero-copy value storage

### API Additions
- Bulk operations (getMany, setMany)
- Atomic operations (increment, compareAndSwap)
- Subscription/observation API
- Cache warming strategies
- Partial key matching

### Platform Features
- SwiftUI property wrapper for reactive updates
- Combine publisher for cache events
- AsyncSequence support for iteration
- Swift Macros for compile-time optimization

### Integration
- Redis protocol compatibility
- Memcached protocol support
- CloudKit backing store
- Core Data integration