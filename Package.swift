import PackageDescription

let package = Package(
    name: "MySQLDriver",
    dependencies: [
    	// Robust MySQL interface for Swift.
   		.Package(url: "https://github.com/vapor/mysql.git", majorVersion: 2),
   		// Swift models, relationships, and querying for NoSQL and SQL databases.
   		.Package(url: "https://github.com/vapor/fluent.git", majorVersion: 2),
   		// Random number generation
   		.Package(url: "https://github.com/vapor/random.git", majorVersion: 1),
    ]
)
