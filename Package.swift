// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlyDistSwift",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "FlyDistSwift",
            path: "Sources"
        ),
    ]
)
