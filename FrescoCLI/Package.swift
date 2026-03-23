// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FrescoCLI",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(path: "../FrescoCore"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "FrescoCLI",
            dependencies: [
                "FrescoCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "FrescoCLITests",
            dependencies: ["FrescoCLI"]
        ),
    ]
)