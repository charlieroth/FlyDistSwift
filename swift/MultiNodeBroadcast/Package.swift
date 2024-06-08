// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MultiNodeBroadcast",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MultiNodeBroadcast",
            path: "Sources"
        ),
    ]
)
