import Async
import XCTest
import FluentBenchmark
import Dispatch
import FluentMySQL

class FluentMySQLTests: XCTestCase {
    var benchmarker: Benchmarker<MySQLDatabase>!
    let loop = DispatchEventLoop(label: "test")
    
    override func setUp() {
        let database = MySQLDatabase(
            hostname: "localhost",
            user: "root",
            password: nil,
            database: "vapor_test"
        )

        let conn = try! database.makeConnection(from: .init(), on: loop).blockingAwait()
        try! conn.connection.administrativeQuery("DROP DATABASE vapor_test").blockingAwait()
        try! conn.connection.administrativeQuery("CREATE DATABASE vapor_test;").blockingAwait()
        
        benchmarker = Benchmarker(database, config: .init(), on: loop, onFail: XCTFail)
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
        try benchmarker.benchmarkChunking_withSchema().blockingAwait(timeout: .seconds(60))
    }

    /// https://github.com/vapor/vapor/issues/1334
    func testColumnNotSetToAutoincrementingID() throws {
        final class Foo: Model, Migration {
            typealias Database = MySQLDatabase
            static var idKey = \Foo.id
            var id: Int?
            var bar: String
            init(id: Int? = nil, bar: String) {
                self.id = id
                self.bar = bar
            }
        }
        let conn = try benchmarker.database.makeConnection(from: .init(), on: loop).blockingAwait(timeout: .seconds(60))
        try Foo.prepare(on: conn).blockingAwait(timeout: .seconds(60))
        let test = Foo(bar: "baz")
        try test.save(on: conn).blockingAwait()
    }
    
    static let allTests = [
        ("testSchema", testSchema),
        ("testModels", testModels),
        ("testRelations", testRelations),
        ("testTimestampable", testTimestampable),
        ("testTransactions", testTransactions),
        ("testChunking", testChunking),
        ("testColumnNotSetToAutoincrementingID", testColumnNotSetToAutoincrementingID),
    ]
}
