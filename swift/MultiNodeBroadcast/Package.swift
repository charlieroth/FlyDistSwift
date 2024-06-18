// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MultiNodeBroadcast",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MultiNodeBroadcast",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            path: "Sources"
        ),
    ]
)
