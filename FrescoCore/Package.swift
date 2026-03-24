// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FrescoCore",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(name: "FrescoCore", targets: ["FrescoCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "FrescoCore",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
        .testTarget(
            name: "FrescoCoreTests",
            dependencies: ["FrescoCore"]
        ),
    ]
)