# Thread Safety in Swift with Actors

A comprehensive guide to implementing thread-safe types in Swift using actors, moving beyond traditional lock-based approaches.

## Table of Contents

- [Overview](#overview)
- [The Problem with Traditional Approaches](#the-problem-with-traditional-approaches)
- [Introducing Actors](#introducing-actors)
- [Basic Actor Implementation](#basic-actor-implementation)
- [Actor Reentrancy](#actor-reentrancy)
- [Best Practices](#best-practices)
- [When to Use Actors vs Locks](#when-to-use-actors-vs-locks)

## Overview

Swift actors provide a modern, compile-time-safe approach to implementing thread-safe types. Unlike traditional lock-based solutions, actors offer:

- ✅ **Compile-time thread safety verification**
- ✅ **Automatic isolation of mutable state**
- ✅ **No manual lock management**
- ✅ **Built-in protection against data races**

## The Problem with Traditional Approaches

### Lock-Based Implementation (Error-Prone)

```swift
@dynamicMemberLookup final class Store<State, Action> {
    typealias Reduce = (State, Action) -> State
    
    private var state: State
    private let reduce: Reduce
    private let lock = NSRecursiveLock()
    
    init(state: State, reduce: @escaping Reduce) {
        self.state = state
        self.reduce = reduce
    }
    
    subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        lock.withLock {
            state[keyPath: keyPath]
        }
    }
    
    func send(_ action: Action) {
        lock.withLock {
            state = reduce(state, action)
        }
    }
}
```

### Issues with Lock-Based Approach

1. **Manual Lock Management**: You must remember to wrap every state access with `withLock`
2. **Easy to Forget**: Missing a single `withLock` call breaks thread safety
3. **Performance**: Locks completely block threads, potentially causing performance issues
4. **No Compile-Time Safety**: The compiler can't verify thread safety

## Introducing Actors

Actors are reference types (like classes) that automatically protect their stored properties from concurrent access.

### Key Benefits

- **Actor Isolation**: Guarantees exclusive access to stored properties
- **Compile-Time Verification**: Swift compiler ensures thread safety
- **Automatic Protection**: No manual lock management required
- **Suspension Points**: Uses `await` for cooperative concurrency

## Basic Actor Implementation

### Simple Actor Example

```swift
@dynamicMemberLookup actor Store<State, Action> {
    typealias Reduce = (State, Action) -> State
    
    private var state: State
    private let reduce: Reduce
    
    init(state: State, reduce: @escaping Reduce) {
        self.state = state
        self.reduce = reduce
    }
    
    subscript<T>(dynam
