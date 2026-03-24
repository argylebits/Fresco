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
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "FrescoCore",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Configuration", package: "swift-configuration"),
            ]
        ),
        .testTarget(
            name: "FrescoCoreTests",
            dependencies: ["FrescoCore"]
        ),
    ]
)