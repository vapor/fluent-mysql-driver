// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "fluent-mysql-driver",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "FluentMySQLDriver", targets: ["FluentMySQLDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.51.0"),
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.9.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
    ],
    targets: [
        .target(
            name: "FluentMySQLDriver",
            dependencies: [
                .product(name: "FluentKit", package: "fluent-kit"),
                .product(name: "FluentSQL", package: "fluent-kit"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "MySQLKit", package: "mysql-kit"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "FluentMySQLDriverTests",
            dependencies: [
                .product(name: "FluentBenchmark", package: "fluent-kit"),
                .target(name: "FluentMySQLDriver"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency=complete"),
] }
