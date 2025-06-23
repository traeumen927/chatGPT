// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "chatGPT",
    targets: [
        .executableTarget(
            name: "chatGPT",
            path: "chatGPT"
        ),
        .testTarget(
            name: "chatGPTTests",
            dependencies: ["chatGPT"],
            path: "chatGPTTests"
        )
    ]
)
