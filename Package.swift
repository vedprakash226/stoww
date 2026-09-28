// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Stow",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Stow",
            dependencies: [],
            path: "Sources/Stow"
        ),
    ]
)
