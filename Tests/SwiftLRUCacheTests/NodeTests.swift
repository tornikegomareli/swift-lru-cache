import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("LRU Cache Node Tests")
struct NodeTests {
    @Test("Node can store key-value pairs")
    func testNodeBasicStorage() {
        let node = LRUNode<String, Int>(key: "test", value: 42)

        #expect(node.key == "test")
        #expect(node.value == 42)
    }

    @Test("Node has nil prev and next by default")
    func testNodeLinksAreNilByDefault() {
        let node = LRUNode<String, String>(key: "key", value: "value")

        #expect(node.prev == nil)
        #expect(node.next == nil)
    }

    @Test("Node can link to other nodes")
    func testNodeLinking() {
        let node1 = LRUNode<Int, String>(key: 1, value: "first")
        let node2 = LRUNode<Int, String>(key: 2, value: "second")
        let node3 = LRUNode<Int, String>(key: 3, value: "third")

        node1.next = node2
        node2.prev = node1
        node2.next = node3
        node3.prev = node2

        #expect(node1.next === node2)
        #expect(node2.prev === node1)
        #expect(node2.next === node3)
        #expect(node3.prev === node2)
    }

    @Test("Node prevents retain cycles with weak prev reference")
    func testNodeWeakPrevReference() {
        var node1: LRUNode<String, Int>? = LRUNode(key: "first", value: 1)
        let node2: LRUNode<String, Int>? = LRUNode(key: "second", value: 2)

        node1?.next = node2
        node2?.prev = node1

        node1 = nil

        #expect(node2?.prev == nil)
    }

    @Test("Node can store size metadata")
    func testNodeSizeMetadata() {
        let node = LRUNode<String, Data>(key: "data", value: Data(repeating: 0, count: 1_024))
        node.size = 1_024

        #expect(node.size == 1_024)
    }

    @Test("Node can store TTL metadata")
    func testNodeTTLMetadata() {
        let node = LRUNode<String, String>(key: "temp", value: "temporary")
        let ttl: TimeInterval = 300
        let insertTime = Date()

        node.ttl = ttl
        node.insertTime = insertTime

        #expect(node.ttl == ttl)
        #expect(node.insertTime == insertTime)
    }

    @Test("Node is a reference type")
    func testNodeIsReferenceType() {
        let node1 = LRUNode<String, Int>(key: "test", value: 100)
        let node2 = node1

        node2.value = 200

        #expect(node1.value == 200)
        #expect(node2.value == 200)
        #expect(node1 === node2)
    }

    @Test("Node can be moved in list")
    func testNodeCanBeMoved() {
        let node1 = LRUNode<String, Int>(key: "a", value: 1)
        let node2 = LRUNode<String, Int>(key: "b", value: 2)
        let node3 = LRUNode<String, Int>(key: "c", value: 3)

        node1.next = node2
        node2.prev = node1
        node2.next = node3
        node3.prev = node2

        node1.prev = node2
        node2.next = node1
        node2.prev = nil
        node1.next = node3
        node3.prev = node1

        #expect(node2.prev == nil)
        #expect(node2.next === node1)
        #expect(node1.prev === node2)
        #expect(node1.next === node3)
    }
}
