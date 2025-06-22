# Swift LRU Cache - Task List

## Setup and Configuration

- [ ] Update Package.swift with proper package information and Swift 6.1 tools version
- [ ] Create proper directory structure under Sources/SwiftLRUCache
- [ ] Set up Swift Testing framework in Package.swift
- [ ] Configure benchmarking targets
- [ ] Add GitHub workflow for CI/CD
- [ ] Set up code formatting configuration (.swift-format)

## Core Data Structures

- [ ] Implement Node class/struct for doubly-linked list
  - [ ] Generic over Key and Value types
  - [ ] Properties: key, value, prev, next, size, ttl, insertTime
  - [ ] Make it a class for reference semantics
- [ ] Design LRUCache main class structure
  - [ ] Generic parameters with appropriate constraints
  - [ ] Private properties for internal state
  - [ ] Thread safety considerations

## Configuration System

- [ ] Create Configuration struct with all options
  - [ ] max: Int?
  - [ ] maxSize: Int?
  - [ ] ttl: TimeInterval?
  - [ ] ttlResolution: TimeInterval
  - [ ] ttlAutopurge: Bool
  - [ ] updateAgeOnGet: Bool
  - [ ] updateAgeOnHas: Bool
  - [ ] allowStale: Bool
  - [ ] sizeCalculation: ((Value, Key) -> Int)?
  - [ ] dispose: ((Value, Key, DisposeReason) -> Void)?
  - [ ] onInsert: ((Value, Key, InsertReason) -> Void)?
  - [ ] disposeAfter: ((Value, Key, DisposeReason) -> Void)?
  - [ ] noDisposeOnSet: Bool
  - [ ] noUpdateTTL: Bool
  - [ ] maxEntrySize: Int?
  - [ ] noDeleteOnStaleGet: Bool
- [ ] Implement configuration validation
- [ ] Create DisposeReason and InsertReason enums

## Core Functionality

### Basic Operations
- [ ] Implement init(configuration:)
  - [ ] Validate configuration
  - [ ] Allocate internal structures
  - [ ] Set up initial state
- [ ] Implement get(_:options:)
  - [ ] O(1) lookup via dictionary
  - [ ] Move to head of list (MRU)
  - [ ] Handle TTL checking
  - [ ] Update age if configured
  - [ ] Handle stale items
- [ ] Implement set(_:value:options:)
  - [ ] Check size constraints
  - [ ] Evict LRU items if needed
  - [ ] Update or insert node
  - [ ] Call disposal callbacks
  - [ ] Handle TTL setting
- [ ] Implement has(_:)
  - [ ] Check existence
  - [ ] Handle TTL if configured
  - [ ] Update age if configured
- [ ] Implement delete(_:)
  - [ ] Remove from dictionary and list
  - [ ] Call disposal callbacks
  - [ ] Update size tracking
- [ ] Implement clear()
  - [ ] Call disposal callbacks for all items
  - [ ] Reset all internal state

### List Management
- [ ] Implement moveToHead(node:) - Move node to MRU position
- [ ] Implement removeNode(node:) - Remove node from list
- [ ] Implement evictLRU() - Remove least recently used item
- [ ] Implement proper head/tail management

### Advanced Operations
- [ ] Implement peek(_:) - Get without updating position
- [ ] Implement pop() - Remove and return LRU item
- [ ] Implement forEach(_:) - Iterate in LRU order
- [ ] Implement entries() -> [(Key, Value)]
- [ ] Implement keys() -> [Key]
- [ ] Implement values() -> [Value]
- [ ] Implement dump() - Debug representation

## TTL Support

- [ ] Create TTLManager component
  - [ ] Track insertion times
  - [ ] Check expiration on access
  - [ ] Handle TTL resolution
- [ ] Implement purgeStale()
  - [ ] Scan all items for expiration
  - [ ] Remove expired items
  - [ ] Call disposal callbacks
- [ ] Implement getRemainingTTL(_:)
- [ ] Add TTL refresh logic on get/has
- [ ] Implement automatic purging if configured

## Size Calculation

- [ ] Create SizeTracker component
  - [ ] Track individual item sizes
  - [ ] Maintain total cache size
  - [ ] Handle custom size calculators
- [ ] Implement size-based eviction
  - [ ] Check maxSize constraints
  - [ ] Evict items until under limit
  - [ ] Handle maxEntrySize
- [ ] Add size validation on set

## Advanced Features

### Fetch Support
- [ ] Implement fetch(_:options:) async method
  - [ ] Check cache first
  - [ ] Handle stale-while-revalidate
  - [ ] Support AbortSignal equivalent
  - [ ] Background refresh support
  - [ ] Handle fetch failures
- [ ] Create FetchOptions struct
- [ ] Implement fetch status tracking

### Memo Support  
- [ ] Implement memo(_:options:compute:) method
  - [ ] Cache computation results
  - [ ] Handle async computations
  - [ ] Support error handling
- [ ] Create MemoOptions struct

### Status Tracking
- [ ] Create Status struct for operation tracking
- [ ] Implement status updates for all operations
- [ ] Add performance metrics

## Thread Safety

- [ ] Evaluate actor vs lock-based approach
- [ ] Implement chosen synchronization method
- [ ] Ensure all public methods are thread-safe
- [ ] Add concurrent access tests
- [ ] Document thread safety guarantees

## Error Handling

- [ ] Create CacheError enum
  - [ ] ConfigurationError cases
  - [ ] SizeExceededError
  - [ ] InvalidKeyError
- [ ] Add proper error handling to all methods
- [ ] Use Result type where appropriate

## Testing

### Unit Tests
- [ ] Test basic get/set/delete operations
- [ ] Test LRU eviction behavior
- [ ] Test size-based eviction
- [ ] Test TTL functionality
  - [ ] Basic expiration
  - [ ] TTL refresh
  - [ ] Stale item handling
- [ ] Test disposal callbacks
- [ ] Test edge cases
  - [ ] Empty cache
  - [ ] Single item
  - [ ] Full cache
  - [ ] Zero/negative configuration values
- [ ] Test configuration validation

### Integration Tests
- [ ] Test real-world usage patterns
- [ ] Test with different data types
- [ ] Test memory behavior under pressure
- [ ] Test performance characteristics

### Concurrency Tests
- [ ] Test concurrent reads
- [ ] Test concurrent writes
- [ ] Test mixed concurrent operations
- [ ] Test for race conditions
- [ ] Test for deadlocks

### Performance Tests
- [ ] Benchmark get operations
- [ ] Benchmark set operations
- [ ] Benchmark eviction performance
- [ ] Compare with other cache implementations
- [ ] Test with large datasets

## Documentation

- [ ] Write comprehensive README
  - [ ] Installation instructions
  - [ ] Basic usage examples
  - [ ] Advanced features
  - [ ] Performance characteristics
  - [ ] Comparison with Node.js version
- [ ] Add DocC documentation to all public APIs
- [ ] Create usage examples
- [ ] Document migration from other caches
- [ ] Add performance tuning guide

## Optimization

- [ ] Profile and identify hot paths
- [ ] Optimize node allocation
- [ ] Minimize ARC overhead
- [ ] Consider unsafe operations for performance
- [ ] Implement lazy TTL checking
- [ ] Optimize size calculations

## Additional Features

- [ ] Add property wrapper for SwiftUI integration
- [ ] Create Combine publisher for cache events
- [ ] Add AsyncSequence conformance
- [ ] Implement Codable support for persistence
- [ ] Add debug descriptions

## Benchmarking

- [ ] Create comprehensive benchmark suite
- [ ] Compare with Node.js implementation
- [ ] Test different cache sizes
- [ ] Test different access patterns
- [ ] Generate performance reports

## Package and Release

- [ ] Add LICENSE file
- [ ] Create CHANGELOG.md
- [ ] Set up semantic versioning
- [ ] Create release workflow
- [ ] Publish to Swift Package Index

## Completed Work

*This section will be updated as tasks are completed*