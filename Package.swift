// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftLRUCache",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SwiftLRUCache",
            targets: ["SwiftLRUCache"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.54.0")
    ],
    targets: [
        .target(
            name: "SwiftLRUCache",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")
            ]
        ),
        .testTarget(
            name: "SwiftLRUCacheTests",
            dependencies: ["SwiftLRUCache"],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")
            ]
        ),
    ]
)
