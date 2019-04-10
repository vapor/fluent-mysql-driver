// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "fluent-mysql-driver",
    products: [
        .library(name: "FluentMySQLDriver", targets: ["FluentMySQLDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", .branch("master")),
        .package(url: "https://github.com/vapor/nio-mysql.git", .branch("master")),
        .package(url: "https://github.com/vapor/sql.git", .branch("master")),
        .package(url: "https://github.com/vapor/nio-kit.git", .branch("master")),
    ],
    targets: [
        .target(name: "FluentMySQLDriver", dependencies: [
            "FluentKit",
            "FluentSQL",
            "NIOKit",
            "NIOMySQL",
            "SQLKit"
        ]),
        .testTarget(name: "FluentMySQLDriverTests", dependencies: ["FluentBenchmark", "FluentMySQLDriver"]),
    ]
)
