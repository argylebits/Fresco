// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FrescoCore",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(name: "FrescoCore", targets: ["FrescoCore"]),
    ],
    targets: [
        .target(
            name: "FrescoCore"
        ),
        .testTarget(
            name: "FrescoCoreTests",
            dependencies: ["FrescoCore"]
        ),
    ]
)