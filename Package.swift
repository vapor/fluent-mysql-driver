// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "fluent-mysql-driver",
    products: [
        .library(name: "FluentMySQLDriver", targets: ["FluentMySQLDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.0.0-alpha.2"),
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.0.0-alpha.1"),
    ],
    targets: [
        .target(name: "FluentMySQLDriver", dependencies: [
            "FluentKit",
            "FluentSQL",
            "MySQLKit"
        ]),
        .testTarget(name: "FluentMySQLDriverTests", dependencies: ["FluentBenchmark", "FluentMySQLDriver"]),
    ]
)
