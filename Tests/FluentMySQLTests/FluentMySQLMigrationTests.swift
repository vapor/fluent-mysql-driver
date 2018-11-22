import FluentBenchmark
import FluentMySQL
import Fluent
import XCTest

class FluentMySQLMigrationTests: XCTestCase {
    var benchmarker: Benchmarker<MySQLDatabase>!
    var database: MySQLDatabase!
    
    override func setUp() {
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let config = MySQLDatabaseConfig(
            hostname: "localhost",
            port: 3306,
            username: "vapor_username",
            password: "vapor_password",
            database: "vapor_database",
            transport: .cleartext
        )
        database = MySQLDatabase(config: config)
        benchmarker = try! Benchmarker(database, on: eventLoop, onFail: XCTFail)
    }
    
    func testMySQLDeleteColumns() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { _ = try? Parent.revert(on: conn).wait() }
        
        let dropResults = try conn.simpleQuery("DROP TABLE IF EXISTS \(Parent.entity);").wait()
        XCTAssertEqual(dropResults.count, 0)
        
        _ = try Parent.prepare(on: conn).wait()
        _ = try Parent(id: nil, name: "A").save(on: conn).wait()

        let preSelectResults = try conn.raw("SELECT * FROM \(Parent.entity);").all().wait()
        XCTAssertEqual(preSelectResults.count, 1)
        XCTAssertEqual(preSelectResults[0].count, 2) // 2 columns
        
        struct DropParentName: Migration {
            static let migrationName = "drop_parent_name"
            
            typealias Database = MySQLDatabase
            
            static func prepare(on connection: MySQLConnection) -> Future<Void> {
                return MySQLDatabase.update(Parent.self, on: connection) { updater in
                    updater.deleteField(for: \Parent.name)
                }
            }

            static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
                return conn.eventLoop.newSucceededFuture(result: ())
            }
        }
        
        _ = try DropParentName.prepare(on: conn).wait()
        
        let postSelectResults = try conn.raw("SELECT * FROM \(Parent.entity);").all().wait()
        XCTAssertEqual(postSelectResults.count, 1)
        XCTAssertEqual(postSelectResults[0].count, 1) // 1 columns
        XCTAssertEqual(postSelectResults[0].keys.first!, MySQLColumn(table: Parent.entity, name: "id"))
    }
    
    static let allTests = [
        ("testMySQLDeleteColumns", testMySQLDeleteColumns),
    ]
}
