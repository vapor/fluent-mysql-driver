import PackageDescription

let package = Package(
    name: "FluentMySQL",
    dependencies: [
   		.Package(url: "https://github.com/qutheory/mysql.git", majorVersion: 0, minor: 3),
   		.Package(url: "https://github.com/qutheory/fluent.git", majorVersion: 0, minor: 8),
    ]
)
