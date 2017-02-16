import PackageDescription

let package = Package(
    name: "FluentMySQL",
    dependencies: [
    	// Robust MySQL interface for Swift.
   		.Package(url: "https://github.com/vapor/mysql.git", Version(2,0,0, prereleaseIdentifiers: ["alpha"])),
   		// Swift models, relationships, and querying for NoSQL and SQL databases.
   		.Package(url: "https://github.com/vapor/fluent.git", Version(2,0,0, prereleaseIdentifiers: ["alpha"]))
    ]
)
