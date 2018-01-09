import Async
import XCTest
import FluentBenchmark
import Dispatch
import FluentMySQL

let testHostname: String  = "localhost"
let testUsername: String  = "root"
let testPassword: String? = nil
let testDatabase: String  = "vapor_test"

class FluentMySQLTests: XCTestCase {
    var benchmarker: Benchmarker<MySQLDatabase>!
    let loop = DispatchEventLoop(label: "test")
    var didCreateDatabase = false
    
    override func setUp() {
        // This "extra" connection allows creating the test database
        // automatically without experiencing "no database selected" errors
        // later.
        //
        // The database is deliberately created without the use of `IF NOT EXISTS`
        // so no one's data will be accidentally erased. (This is already
        // unlikely since no one should be running with no root password, but
        // better to be too careful than not careful enough.)
        let setupDatabase = MySQLDatabase(hostname: testHostname, user: testUsername, password: testPassword, database: "")
        let setupConn = try! setupDatabase.makeConnection(using: .init(), on: loop).blockingAwait()

        try! setupConn.administrativeQuery("CREATE DATABASE \(testDatabase)").blockingAwait()
        didCreateDatabase = true

        let database = MySQLDatabase(hostname: testHostname, user: testUsername, password: testPassword, database: testDatabase)

        self.benchmarker = Benchmarker(database, config: .init(), on: loop, onFail: XCTFail)
    }
    
    override func tearDown() {
        // This extra protection is probably unnecessary, but it's here anyway
        // to ensure that we're not relying on `XCTestCase`'s semantics to
        // prevent accidental drops.
        if didCreateDatabase {
            let teardownConn = try! benchmarker.database.makeConnection(using: .init(), on: loop).blockingAwait()
            
            try! teardownConn.administrativeQuery("DROP DATABASE IF EXISTS \(testDatabase)").blockingAwait()
        }
    }
    
    func testSchema() throws {
        try benchmarker.benchmarkSchema().blockingAwait(timeout: .seconds(60))
    }
    
    func testModels() throws {
        try benchmarker.benchmarkModels_withSchema().blockingAwait(timeout: .seconds(60))
    }
    
    func testRelations() throws {
        try benchmarker.benchmarkRelations_withSchema().blockingAwait(timeout: .seconds(60))
    }
    
    func testTimestampable() throws {
        try benchmarker.benchmarkTimestampable_withSchema().blockingAwait(timeout: .seconds(60))
    }
    
    func testTransactions() throws {
        try benchmarker.benchmarkTransactions_withSchema().blockingAwait(timeout: .seconds(60))
    }
    
    func testChunking() throws {
        // FIXME: uncomment when async recursion is fixed
        // try benchmarker.benchmarkChunking_withSchema().blockingAwait(timeout: .seconds(60))
    }
    
    static let allTests = [
        ("testSchema", testSchema),
        ("testModels", testModels),
        ("testRelations", testRelations),
        ("testTimestampable", testTimestampable),
        ("testTransactions", testTransactions),
        ("testChunking", testChunking),
    ]
}
