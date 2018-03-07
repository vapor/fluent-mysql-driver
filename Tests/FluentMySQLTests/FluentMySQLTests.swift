import Async
import XCTest
import FluentBenchmark
import Dispatch
import FluentMySQL

class FluentMySQLTests: XCTestCase {
    var benchmarker: Benchmarker<MySQLDatabase>!
    var database: MySQLDatabase!

    override func setUp() {
        let eventLoop = MultiThreadedEventLoopGroup(numThreads: 1)
        let config = MySQLDatabaseConfig(
            hostname: "localhost",
            port: 3306,
            username: "vapor_username",
            password: "vapor_password",
            database: "vapor_database"
        )
        database = MySQLDatabase(config: config)
        benchmarker = Benchmarker(database, on: eventLoop, onFail: XCTFail)
    }

    func testSchema() throws {
        try benchmarker.benchmarkSchema()
    }
    
    func testModels() throws {
        try benchmarker.benchmarkModels_withSchema()
    }
    
    func testRelations() throws {
        try benchmarker.benchmarkRelations_withSchema()
    }
    
    func testTimestampable() throws {
        try benchmarker.benchmarkTimestampable_withSchema()
    }
    
//    func testTransactions() throws {
//        try benchmarker.benchmarkTransactions_withSchema()
//    }

    func testChunking() throws {
         try benchmarker.benchmarkChunking_withSchema()
    }
    
    static let allTests = [
        ("testSchema", testSchema),
        ("testModels", testModels),
        ("testRelations", testRelations),
        ("testTimestampable", testTimestampable),
//        ("testTransactions", testTransactions),
        ("testChunking", testChunking),
    ]
}
