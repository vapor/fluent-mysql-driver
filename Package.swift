import PackageDescription

let package = Package(
    name: "FluentMySQL",
    dependencies: [
   		.Package(url: "https://github.com/vapor/mysql.git", majorVersion: 0, minor: 3),
   		.Package(url: "https://github.com/vapor/fluent.git", majorVersion: 0, minor: 8),
    ]
)
