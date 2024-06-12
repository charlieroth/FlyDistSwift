// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "EfficientBroadcast",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "EfficientBroadcast",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            path: "Sources"
        ),
    ]
)
