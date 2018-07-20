// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "FluentMySQL",
    products: [
        .library(name: "FluentMySQL", targets: ["FluentMySQL"]),
    ],
    dependencies: [
        // 🌎 Utility package containing tools for byte manipulation, Codable, OS APIs, and debugging.
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0"),

        // Swift ORM framework (queries, models, and relations) for building NoSQL and SQL database integrations.
        .package(url: "https://github.com/vapor/fluent.git", from: "3.0.0"),

        // 🐬 Pure Swift MySQL client built on non-blocking, event-driven sockets.
        .package(url: "https://github.com/vapor/mysql.git", .revision("994f0ac0d4c0eaa2d9a3edf6d44264fcc8d641b0")),
    ],
    targets: [
        .target(name: "FluentMySQL", dependencies: ["Async", "FluentSQL", "MySQL"]),
        .testTarget(name: "FluentMySQLTests", dependencies: ["FluentBenchmark", "FluentMySQL"]),
    ]
)
