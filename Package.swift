// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sabella",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
    ],
    products: [
        .library(name: "Sabella", targets: ["Sabella"]),
    ],
    targets: [
        .target(name: "Sabella"),
        .testTarget(name: "SabellaTests", dependencies: ["Sabella"]),
    ]
)
