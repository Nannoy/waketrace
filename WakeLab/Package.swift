// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WakeLab",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "WakeLab",
            path: "Sources/WakeLab",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .testTarget(
            name: "WakeLabTests",
            dependencies: [],
            path: "Tests/WakeLabTests"
        )
    ]
)
