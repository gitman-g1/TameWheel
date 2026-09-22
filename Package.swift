// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TameWheel",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TameWheel", targets: ["TameWheel"])
    ],
    targets: [
        .executableTarget(name: "TameWheel"),
        .testTarget(name: "TameWheelTests", dependencies: ["TameWheel"])
    ]
)
