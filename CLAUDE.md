# Swift LRU Cache - Project Instructions

## Overview

This document contains specific instructions for developing the Swift LRU Cache implementation. The goal is to create a high-performance, feature-complete port of the Node.js lru-cache package while maintaining Swift idioms and leveraging Swift 6.1's latest features.

## Key Implementation Principles

### 1. Performance First
- **O(1) Complexity**: All core operations (get, set, delete) MUST maintain O(1) average time complexity
- **Memory Efficiency**: Minimize allocations in hot paths. Pre-allocate where possible
- **Lazy Evaluation**: Don't check TTLs until necessary. Don't calculate sizes unless size tracking is enabled
- **Profile Before Optimizing**: Use Instruments to identify actual bottlenecks

### 2. Swift Idioms
- **Value Semantics Where Appropriate**: Use structs for configuration and options
- **Reference Semantics for Nodes**: Use classes for the linked list nodes to avoid copying
- **Protocol-Oriented Design**: Define protocols for extensibility (e.g., SizeCalculatable)
- **Type Safety**: Leverage Swift's type system to prevent errors at compile time

### 3. Code Style Guidance
- Dont ever use // comments, only use DOCC style of comments but in places where it is very important or code is kinda hard to understand.

### 4. Reference Implementation
- The Node.js lru-cache in the `node-lru-cache/` directory is the reference
- Study `node-lru-cache/src/index.ts` for implementation details
- Maintain feature parity but adapt to Swift conventions
- Key files to study:
  - Main implementation: `node-lru-cache/src/index.ts`
  - Tests for behavior: `node-lru-cache/test/*.ts`

## Architecture Decisions

### Thread Safety Strategy
Choose between:
1. **Actor-based** (Recommended for Swift 6.1):
   ```swift
   actor LRUCache<Key: Hashable, Value> {
       // All state is protected by actor isolation
   }
   ```
2. **Lock-based** (If actor overhead is too high):
   ```swift
   class LRUCache<Key: Hashable, Value> {
       private let lock = NSLock() // or os_unfair_lock
   }
   ```

### Data Structure Implementation
```swift
// Node must be a class for reference semantics
class Node<Key, Value> {
    var key: Key
    var value: Value
    weak var prev: Node?
    var next: Node?
    var size: Int?
    var ttl: TimeInterval?
    var insertTime: Date?
}

// Main cache structure
class LRUCache<Key: Hashable, Value> {
    private var dict: [Key: Node<Key, Value>] = [:]
    private var head: Node<Key, Value>?
    private var tail: Node<Key, Value>?
}
```

## Implementation Guidelines

### When Implementing Core Methods

1. **get(_:)**
   - First check if key exists in dictionary
   - Then check if TTL expired (if TTL is enabled)
   - Move node to head (most recently used)
   - Handle allowStale option
   - Update access time if updateAgeOnGet is true

2. **set(_:value:)**
   - Validate size constraints first
   - Check if key already exists (update vs insert)
   - Evict LRU items if needed to make space
   - Insert/update node in dictionary and list
   - Call appropriate callbacks (dispose, onInsert)

3. **TTL Handling**
   - Store absolute expiration time, not relative TTL
   - Use monotonic clock for time comparisons
   - Only check expiration when item is accessed
   - Implement lazy purging unless ttlAutopurge is true

### Code Style Requirements

1. **Documentation**:
   ```swift
   /// DocC style documentation for all public APIs
   /// - Parameters:
   ///   - key: The key to retrieve
   ///   - options: Optional parameters to override defaults
   /// - Returns: The cached value, or nil if not found
   /// - Complexity: O(1) average case
   public func get(_ key: Key, options: GetOptions? = nil) -> Value?
   ```

2. **Error Handling**:
   - Use throwing functions for operations that can fail
   - Use preconditions for programmer errors
   - Never force unwrap optionals from user input

3. **Naming Conventions**:
   - Follow Swift API Design Guidelines
   - Use clear, descriptive names
   - Avoid abbreviations

## Testing Requirements

### Test Coverage Goals
- Minimum 90% code coverage
- 100% coverage of public API
- Every edge case from Node.js tests should have Swift equivalent

### Critical Test Scenarios
1. **Basic Operations**: get, set, has, delete, clear
2. **LRU Behavior**: Eviction order, moving to head on access
3. **TTL Tests**: Expiration, refresh, stale handling
4. **Size Tests**: Size calculation, size-based eviction
5. **Callback Tests**: dispose, onInsert, disposeAfter
6. **Concurrency Tests**: Thread safety, race conditions
7. **Performance Tests**: O(1) verification, memory usage

### Test Implementation
```swift
import Testing
@testable import SwiftLRUCache

@Test func testBasicLRU() async throws {
    let cache = LRUCache<String, Int>(max: 2)
    cache.set("a", value: 1)
    cache.set("b", value: 2)
    cache.set("c", value: 3) // Should evict "a"
    
    #expect(cache.get("a") == nil)
    #expect(cache.get("b") == 2)
    #expect(cache.get("c") == 3)
}
```

## Performance Optimization Strategies

1. **Node Pool**: Pre-allocate nodes to reduce allocation overhead
2. **Inline TTL Checks**: Make TTL checking inline-able by the compiler
3. **Avoid ARC Overhead**: Use unowned/weak references carefully
4. **Batch Operations**: Implement internal batch methods for bulk operations
5. **Copy-on-Write**: Leverage Swift's COW for value types where appropriate

## Common Pitfalls to Avoid

1. **Retain Cycles**: Be careful with callbacks capturing self
2. **Integer Overflow**: Validate size calculations
3. **Time Drift**: Use monotonic clock for TTL calculations
4. **Thread Starvation**: Don't hold locks during callbacks
5. **Memory Leaks**: Ensure proper cleanup in dispose callbacks

## Development Workflow

1. **Start with Core**: Implement basic get/set/delete first
2. **Add LRU Logic**: Ensure eviction works correctly
3. **Layer Features**: Add TTL, size tracking, callbacks incrementally
4. **Test Continuously**: Write tests alongside implementation
5. **Profile Regularly**: Check performance after each major feature
6. **Reference Node.js**: When in doubt, check how Node.js version behaves

## Debugging Tips

1. **Add Debug Descriptions**: Implement `CustomDebugStringConvertible`
2. **Assertion Checks**: Add assertions to verify internal consistency
3. **Logging Hooks**: Add optional logging for cache operations
4. **Visualization**: Create methods to dump cache state for debugging

## Future Considerations

When implementing, keep these future features in mind:
- Persistence support (design serializable node structure)
- Distributed caching (consider network-friendly key/value types)
- Statistics collection (add hooks for metrics)
- SwiftUI integration (consider @Observable macro)

## Commands to Run Frequently

```bash
# After implementing new features
swift test

# Check performance
swift test --filter Performance

# Before committing
swift-format -i -r Sources/ Tests/
swift build -c release

# Generate documentation
swift package generate-documentation
```

## Questions to Ask

Before implementing each feature, ask:
1. How does the Node.js version handle this?
2. What's the most Swift-like way to implement this?
3. Will this maintain O(1) complexity?
4. How can this be tested thoroughly?
5. What edge cases need to be handled?

## Final Notes

- **Quality over Speed**: Write correct code first, optimize later
- **Test Everything**: If it's not tested, it's broken
- **Document Thoroughly**: Future developers (including yourself) will thank you
- **Follow the Spec**: When in doubt, match Node.js lru-cache behavior
- **Be Idiomatic**: Write Swift code that Swift developers would expect

Remember: We're building a production-ready cache that developers will rely on. Take the time to get it right.

## Additional Resources

### Swift Development Resources
- **Swift Argument Parser**: See @ai_files/argument_parser.md for command-line tool patterns if we add CLI utilities
- **Code Review Guidelines**: See @ai_files/pr_review.md for comprehensive pull request review checklist
- **Swift Borrowing/Consuming**: See @ai_files/swift-borrowing.md for noncopyable types and ownership patterns (relevant for performance optimization)