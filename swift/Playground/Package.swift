// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Playground",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-distributed-actors.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "Playground",
            dependencies: [
                .product(name: "DistributedCluster", package: "swift-distributed-actors")
            ],
            path: "Sources"
        ),
    ]
)
