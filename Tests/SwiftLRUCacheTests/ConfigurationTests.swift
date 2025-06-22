import Testing
import Foundation
@testable import SwiftLRUCache

@Suite("Configuration Tests")
struct ConfigurationTests {

    @Test("Configuration requires at least one constraint")
    func testConfigurationRequiresConstraint() throws {
        #expect(throws: ConfigurationError.noConstraints) {
            try Configuration<String, String>()
        }
    }

    @Test("Configuration accepts max constraint")
    func testConfigurationWithMax() throws {
        let config = try Configuration<String, String>(max: 100)
        #expect(config.max == 100)
        #expect(config.maxSize == nil)
        #expect(config.ttl == nil)
    }

    @Test("Configuration accepts maxSize constraint")
    func testConfigurationWithMaxSize() throws {
        let config = try Configuration<String, String>(maxSize: 1024)
        #expect(config.max == nil)
        #expect(config.maxSize == 1024)
        #expect(config.ttl == nil)
    }

    @Test("Configuration accepts TTL constraint")
    func testConfigurationWithTTL() throws {
        let config = try Configuration<String, String>(ttl: 300)
        #expect(config.max == nil)
        #expect(config.maxSize == nil)
        #expect(config.ttl == 300)
    }

    @Test("Configuration accepts multiple constraints")
    func testConfigurationWithMultipleConstraints() throws {
        let config = try Configuration<String, String>(max: 100, maxSize: 1024, ttl: 300)
        #expect(config.max == 100)
        #expect(config.maxSize == 1024)
        #expect(config.ttl == 300)
    }

    @Test("Configuration validates positive max")
    func testConfigurationValidatesPositiveMax() throws {
        #expect(throws: ConfigurationError.invalidMax) {
            try Configuration<String, String>(max: 0)
        }

        #expect(throws: ConfigurationError.invalidMax) {
            try Configuration<String, String>(max: -1)
        }
    }

    @Test("Configuration validates positive maxSize")
    func testConfigurationValidatesPositiveMaxSize() throws {
        #expect(throws: ConfigurationError.invalidMaxSize) {
            try Configuration<String, String>(maxSize: 0)
        }

        #expect(throws: ConfigurationError.invalidMaxSize) {
            try Configuration<String, String>(maxSize: -1)
        }
    }

    @Test("Configuration validates positive TTL")
    func testConfigurationValidatesPositiveTTL() throws {
        #expect(throws: ConfigurationError.invalidTTL) {
            try Configuration<String, String>(ttl: 0)
        }

        #expect(throws: ConfigurationError.invalidTTL) {
            try Configuration<String, String>(ttl: -1)
        }
    }

    @Test("Configuration has default values")
    func testConfigurationDefaults() throws {
        let config = try Configuration<String, String>(max: 100)

        #expect(config.ttlResolution == 1)
        #expect(config.ttlAutopurge == false)
        #expect(config.updateAgeOnGet == false)
        #expect(config.updateAgeOnHas == false)
        #expect(config.allowStale == false)
        #expect(config.noDisposeOnSet == false)
        #expect(config.noUpdateTTL == false)
        #expect(config.noDeleteOnStaleGet == false)
    }

    @Test("Configuration accepts custom dispose handler")
    func testConfigurationWithDisposeHandler() throws {
        var disposedItems: [(String, Int, DisposeReason)] = []

        var config = try Configuration<String, Int>(max: 10)
        config.dispose = { value, key, reason in
            disposedItems.append((key, value, reason))
        }

        #expect(config.dispose != nil)

        config.dispose?(42, "test", .evict)
        #expect(disposedItems.count == 1)
        #expect(disposedItems[0].0 == "test")
        #expect(disposedItems[0].1 == 42)
        #expect(disposedItems[0].2 == .evict)
    }

    @Test("Configuration accepts size calculation function")
    func testConfigurationWithSizeCalculation() throws {
        var config = try Configuration<String, Data>(maxSize: 1024)
        config.sizeCalculation = { value, _ in
            value.count
        }

        #expect(config.sizeCalculation != nil)

        let data = Data(repeating: 0, count: 256)
        let size = config.sizeCalculation?(data, "test")
        #expect(size == 256)
    }

    @Test("Configuration validates maxEntrySize")
    func testConfigurationMaxEntrySize() throws {
        var config = try Configuration<String, String>(maxSize: 1024)
        config.maxEntrySize = 512

        #expect(config.maxEntrySize == 512)
        #expect(config.maxEntrySize! <= config.maxSize!)
    }

    @Test("Configuration is a value type")
    func testConfigurationIsValueType() throws {
        let config1 = try Configuration<String, String>(max: 100)
        var config2 = config1

        config2.ttl = 300

        #expect(config1.ttl == nil)
        #expect(config2.ttl == 300)
    }
}