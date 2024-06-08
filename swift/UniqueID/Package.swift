// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "UniqueID",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "UniqueID",
            path: "Sources"
        ),
    ]
)
