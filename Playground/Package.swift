// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Playground",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-distributed-actors.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
        .package(url: "https://github.com/vapor/console-kit.git", .upToNextMajor(from: "4.14.3")),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Playground",
            dependencies: [
                .product(name: "DistributedCluster", package: "swift-distributed-actors"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ConsoleKit", package: "console-kit"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            path: "Sources"
        ),
    ]
)
