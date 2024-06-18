// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Echo",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Echo",
            path: "Sources"
        ),
    ]
)
