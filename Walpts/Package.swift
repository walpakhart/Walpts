// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Walpts",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Walpts", targets: ["Walpts"]),
    ],
    targets: [
        .executableTarget(
            name: "Walpts",
            path: "Sources"
        ),
    ]
)
