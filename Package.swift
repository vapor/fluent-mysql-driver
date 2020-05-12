// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "fluent-mysql-driver",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "FluentMySQLDriver", targets: ["FluentMySQLDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", .branch("prepared-migration-filtering")),
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.0.0-rc.1.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "FluentMySQLDriver", dependencies: [
            .product(name: "FluentKit", package: "fluent-kit"),
            .product(name: "FluentSQL", package: "fluent-kit"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "MySQLKit", package: "mysql-kit"),
        ]),
        .testTarget(name: "FluentMySQLDriverTests", dependencies: [
            .product(name: "FluentBenchmark", package: "fluent-kit"),
            .target(name: "FluentMySQLDriver"),
        ]),
    ]
)
