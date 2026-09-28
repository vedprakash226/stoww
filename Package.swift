// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Stoww",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Stoww",
            dependencies: [],
            path: "Sources/Stoww"
        ),
    ]
)
