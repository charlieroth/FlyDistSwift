// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SingleNodeBroadcast",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SingleNodeBroadcast",
            path: "Sources"
        ),
    ]
)
