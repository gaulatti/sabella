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
        .executable(name: "SabellaCatalog", targets: ["SabellaCatalog"]),
        .executable(name: "SabellaShellExamples", targets: ["SabellaShellExamples"]),
    ],
    targets: [
        .target(
            name: "Sabella",
            resources: [.copy("Resources/Fonts")]
        ),
        .target(name: "SabellaCatalogSupport"),
        .executableTarget(
            name: "SabellaCatalog",
            dependencies: ["Sabella", "SabellaCatalogSupport"]
        ),
        .executableTarget(name: "SabellaShellExamples", dependencies: ["Sabella"]),
        .testTarget(
            name: "SabellaTests",
            dependencies: ["Sabella", "SabellaCatalogSupport"]
        ),
    ]
)
