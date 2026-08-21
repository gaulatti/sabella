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
        .executable(name: "SabellaShellExamples", targets: ["SabellaShellExamples"]),
    ],
    targets: [
        .target(name: "Sabella"),
        .executableTarget(name: "SabellaShellExamples", dependencies: ["Sabella"]),
        .testTarget(name: "SabellaTests", dependencies: ["Sabella"]),
    ]
)
