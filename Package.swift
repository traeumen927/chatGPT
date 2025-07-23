// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var targets: [Target] = []
#if os(iOS)
targets.append(
    .executableTarget(
        name: "chatGPT",
        path: "chatGPT"
    )
)
#endif
targets.append(
    .testTarget(
        name: "chatGPTTests",
        dependencies: [],
        path: "chatGPTTests"
    )
)

let package = Package(
    name: "chatGPT",
    defaultLocalization: "ko",
    platforms: [.iOS(.v18)],
    targets: targets
)
