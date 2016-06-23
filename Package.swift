import PackageDescription

let package = Package(
    name: "FluentMySQL",
    dependencies: [
   		.Package(url: "https://github.com/qutheory/mysql.git", majorVersion: 0, minor: 2),
   		.Package(url: "https://github.com/qutheory/fluent.git", majorVersion: 0, minor: 7),
    ]
)
