// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LayoutPresets",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "LayoutPresets", targets: ["LayoutPresets"])
    ],
    targets: [
        .executableTarget(name: "LayoutPresets", path: "Sources")
    ]
)
