// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "PhotoMetaKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "PhotoMetaKit",
            targets: ["PhotoMetaKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.14.1")
    ],
    targets: [
        .target(
            name: "PhotoMetaKit",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        ),
        .testTarget(
            name: "PhotoMetaKitTests",
            dependencies: ["PhotoMetaKit"]
        ),
    ]
)
