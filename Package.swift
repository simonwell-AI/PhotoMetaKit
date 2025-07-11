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
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.4"),
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "PhotoMetaKit",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "Supabase", package: "supabase-swift")
            ]
        ),
        .testTarget(
            name: "PhotoMetaKitTests",
            dependencies: ["PhotoMetaKit"]
        ),
    ]
)
