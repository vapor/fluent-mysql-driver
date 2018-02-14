// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "FluentMySQL",
    products: [
        .library(name: "FluentMySQL", targets: ["FluentMySQL"]),
    ],
    dependencies: [
        // Swift ORM (queries, models, and relations) for NoSQL and SQL databases.
        .package(url: "https://github.com/vapor/fluent.git", .exact("3.0.0-beta.2")),
        // Robust MySQL interface for Swift
        .package(url: "https://github.com/vapor/mysql.git", .exact("3.0.0-beta.2")),
    ],
    targets: [
        .target(name: "FluentMySQL", dependencies: ["Fluent", "FluentSQL", "MySQL"]),
        .testTarget(name: "FluentMySQLTests", dependencies: ["FluentBenchmark", "FluentMySQL"]),
    ]
)
