// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScrollMate",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ScrollMate", targets: ["ScrollMate"])
    ],
    targets: [
        .executableTarget(name: "ScrollMate"),
        .testTarget(name: "ScrollMateTests", dependencies: ["ScrollMate"])
    ]
)
