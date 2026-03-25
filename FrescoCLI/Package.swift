// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FrescoCLI",
    platforms: [
        .macOS(.v26),
    ],
    dependencies: [
        .package(path: "../FrescoCore"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.1"),
        .package(url: "https://github.com/argylebits/swift-version-plugin.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "FrescoCLI",
            dependencies: [
                "FrescoCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            plugins: [
                .plugin(name: "VersionPlugin", package: "swift-version-plugin"),
            ]
        ),
        .testTarget(
            name: "FrescoCLITests",
            dependencies: ["FrescoCLI"]
        ),
    ]
)