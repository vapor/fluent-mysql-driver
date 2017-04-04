import PackageDescription

let beta = Version(2,0,0, prereleaseIdentifiers: ["beta"])

let package = Package(
    name: "MySQLDriver",
    dependencies: [
    	// Robust MySQL interface for Swift.
   		.Package(url: "https://github.com/vapor/mysql.git", beta),
   		// Swift models, relationships, and querying for NoSQL and SQL databases.
   		.Package(url: "https://github.com/vapor/fluent.git", beta),
   		// Random number generation
   		.Package(url: "https://github.com/vapor/random.git", Version(1,0,0, prereleaseIdentifiers: ["beta"]))
    ]
)
