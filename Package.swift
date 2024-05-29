// swift-tools-version:5.8
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
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.48.4"),
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.9.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
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
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
] }
