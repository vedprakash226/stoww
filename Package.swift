// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LaterBin",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "LaterBin",
            dependencies: [],
            path: "Sources/LaterBin"
        ),
    ]
)
