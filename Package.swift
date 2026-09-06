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
    dependencies: [
        .package(
            url: "https://github.com/kingslay/KSPlayer.git",
            revision: "10a40a1c0001d75307ad5922d1d1bc0cb01c89b4"
        ),
    ],
    targets: [
        .target(
            name: "SabellaKSPlayerWorkaround",
            path: "Sources/SabellaKSPlayerWorkaround",
            publicHeadersPath: "include"
        ),
        .target(
            name: "Sabella",
            dependencies: [
                .product(
                    name: "KSPlayer",
                    package: "KSPlayer",
                    condition: .when(platforms: [.tvOS])
                ),
                .target(
                    name: "SabellaKSPlayerWorkaround",
                    condition: .when(platforms: [.tvOS])
                ),
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("Resources/Fonts"),
            ]
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
