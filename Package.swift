// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "FluentMySQL",
    products: [
        .library(name: "FluentMySQL", targets: ["FluentMySQL"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent.git", .branch("beta")),
        .package(url: "https://github.com/vapor/mysql.git", .branch("beta")),
    ],
    targets: [
        .target(name: "FluentMySQL", dependencies: ["Fluent", "FluentSQL", "MySQL"]),
        .testTarget(name: "FluentMySQLTests", dependencies: ["FluentMySQL"]),
    ]
)
