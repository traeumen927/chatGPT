// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.9.0")
]

var targets: [Target] = []
#if os(iOS)
targets.append(
    .executableTarget(
        name: "chatGPT",
        dependencies: [
            .product(name: "RxSwift", package: "RxSwift"),
            .product(name: "RxCocoa", package: "RxSwift")
        ],
        path: "chatGPT"
    )
)
#endif
targets.append(
    .testTarget(
        name: "chatGPTTests",
        dependencies: [
            "chatGPT",
            .product(name: "RxSwift", package: "RxSwift")
        ],
        path: "chatGPTTests"
    )
)

let package = Package(
    name: "chatGPT",
    defaultLocalization: "ko",
    platforms: [.iOS(.v18)],
    dependencies: packageDependencies,
    targets: targets
)
