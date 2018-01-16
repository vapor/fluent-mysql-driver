import Async
import XCTest
import FluentBenchmark
import Dispatch
import FluentMySQL

let testHostname: String  = "localhost"
let testUsername: String  = "root"
let testPassword: String? = nil
let testDatabase: String  = "vapor_test"

var _loop: DefaultEventLoop?
let loop: DefaultEventLoop = {
    if let loop = _loop { return loop }
    
    let l = try! DefaultEventLoop(label: "test")
    
    _loop = l
    
    return l
}()

class FluentMySQLTests: XCTestCase {
    var benchmarker: Benchmarker<MySQLDatabase>!
    
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
        let setupConn = try! setupDatabase.makeConnection(using: .init(), on: loop).await(on: loop)

        _ = try? setupConn.administrativeQuery("CREATE DATABASE \(testDatabase)").await(on: loop)
        didCreateDatabase = true
        setupConn.close()

        let database = MySQLDatabase(hostname: testHostname, user: testUsername, password: testPassword, database: testDatabase)
        self.benchmarker = Benchmarker(database, config: .init(), on: loop, onFail: XCTFail)
    }
    
    override func tearDown() {
        // This extra protection is probably unnecessary, but it's here anyway
        // to ensure that we're not relying on `XCTestCase`'s semantics to
        // prevent accidental drops.
        if didCreateDatabase {
            let setupDatabase = MySQLDatabase(hostname: testHostname, user: testUsername, password: testPassword, database: "")
            let teardownConn = try! setupDatabase.makeConnection(using: .init(), on: loop).await(on: loop)
            
            try! teardownConn.administrativeQuery("DROP DATABASE IF EXISTS \(testDatabase)").await(on: loop)
            teardownConn.close()
        }
    }
    
    func testSchema() throws {
        try benchmarker.benchmarkSchema().await(on: loop)
    }
    
    func testModels() throws {
        try benchmarker.benchmarkModels_withSchema().await(on: loop)
    }
    
    func testRelations() throws {
        try benchmarker.benchmarkRelations_withSchema().await(on: loop)
    }
    
    func testTimestampable() throws {
        try benchmarker.benchmarkTimestampable_withSchema().await(on: loop)
    }
    
    func testTransactions() throws {
        try benchmarker.benchmarkTransactions_withSchema().await(on: loop)
    }
    
    func testChunking() throws {
         try benchmarker.benchmarkChunking_withSchema().await(on: loop)
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
