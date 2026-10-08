// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AQDCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AQDCore", targets: ["AQDCore"])],
    targets: [
        .target(name: "AQDCore"),
        .testTarget(name: "AQDCoreTests", dependencies: ["AQDCore"])
    ]
)
