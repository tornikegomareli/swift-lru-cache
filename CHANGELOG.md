# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial implementation of LRU Cache
- Basic cache operations (get, set, has, delete, clear, peek)
- LRU eviction when cache reaches capacity
- TTL (Time To Live) support with lazy expiration
- Size-based eviction with custom size calculation
- Disposal callbacks for cleanup
- Comprehensive test suite with 41 tests
- GitHub Actions CI/CD workflows
- SwiftLint integration
- Documentation and examples

### Features
- O(1) time complexity for all core operations
- Configurable maximum items and total size limits
- Per-item and default TTL support
- Stale item handling with allowStale option
- TTL refresh on access (updateAgeOnGet/Has)
- Manual purge of expired items
- Automatic purging option (ttlAutopurge)

## [0.1.0] - TBD
- Initial release