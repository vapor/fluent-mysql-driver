import FluentBenchmark
import FluentMySQL
import XCTest

class FluentMySQLTests: XCTestCase {
    var benchmarker: Benchmarker<MySQLDatabase>!
    var database: MySQLDatabase!

    override func setUp() {
        let eventLoop = MultiThreadedEventLoopGroup(numThreads: 1)
        let config = MySQLDatabaseConfig(
            hostname: "192.168.99.100",
            port: 3306,
            username: "vapor_username",
            password: "vapor_password",
            database: "vapor_database"
        )
        database = MySQLDatabase(config: config)
        benchmarker = try! Benchmarker(database, on: eventLoop, onFail: XCTFail)
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
    
    func testTransactions() throws {
        try benchmarker.benchmarkTransactions_withSchema()
    }

    func testChunking() throws {
         try benchmarker.benchmarkChunking_withSchema()
    }

    func testMySQLJoining() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        _ = try conn.simpleQuery("create table tablea (id INT, cola INT);").wait()
        _ = try conn.simpleQuery("create table tableb (colb INT);").wait()
        _ = try conn.simpleQuery("create table tablec (colc INT);").wait()
        defer {
            _ = try? conn.simpleQuery("drop table if exists tablea;").wait()
            _ = try? conn.simpleQuery("drop table if exists tableb;").wait()
            _ = try? conn.simpleQuery("drop table if exists tablec;").wait()
        }

        _ = try conn.simpleQuery("insert into tablea values (1, 1);").wait()
        _ = try conn.simpleQuery("insert into tablea values (2, 2);").wait()
        _ = try conn.simpleQuery("insert into tablea values (3, 3);").wait()
        _ = try conn.simpleQuery("insert into tablea values (4, 4);").wait()

        _ = try conn.simpleQuery("insert into tableb values (1);").wait()
        _ = try conn.simpleQuery("insert into tableb values (2);").wait()
        _ = try conn.simpleQuery("insert into tableb values (3);").wait()

        _ = try conn.simpleQuery("insert into tablec values (2);").wait()
        _ = try conn.simpleQuery("insert into tablec values (3);").wait()
        _ = try conn.simpleQuery("insert into tablec values (4);").wait()

        let all = try A.query(on: conn)
            .join(\B.colb, to: \A.cola)
            .alsoDecode(B.self)
            .join(\C.colc, to: \A.cola)
            .alsoDecode(C.self)
            .all().wait()

        XCTAssertEqual(all.count, 2)
        for ((a, b), c) in all {
            print(a.cola)
            print(b.colb)
            print(c.colc)
        }
    }

    func testMySQLCustomSQL() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        _ = try conn.simpleQuery("create table tablea (id INT, cola INT);").wait()
        defer { _ = try? conn.simpleQuery("drop table if exists tablea;").wait() }
        _ = try conn.simpleQuery("insert into tablea values (1, 1);").wait()
        _ = try conn.simpleQuery("insert into tablea values (2, 2);").wait()
        _ = try conn.simpleQuery("insert into tablea values (3, 3);").wait()
        _ = try conn.simpleQuery("insert into tablea values (4, 4);").wait()

        let all = try A.query(on: conn).customSQL { query in
            let predicate = DataPredicate(column: "cola", comparison: .equal, value: .null)
            query.predicates.append(.predicate(predicate))
        }.all().wait()
        XCTAssertEqual(all.count, 0)
    }

    func testMySQLSet() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        _ = try conn.simpleQuery("create table tablea (id INT, cola INT);").wait()
        defer { _ = try? conn.simpleQuery("drop table if exists tablea;").wait() }
        _ = try conn.simpleQuery("insert into tablea values (1, 1);").wait()
        _ = try conn.simpleQuery("insert into tablea values (2, 2);").wait()

        let builder = A.query(on: conn)
        _ = try builder.update(data: ["cola": 3]).wait()
        _ = try builder.update(data: ["id": 2]).wait()
        let all = try A.query(on: conn).all().wait()
        print(all)
    }

    func testJSONType() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { _ = try? User.revert(on: conn).wait() }
        _ = try User.prepare(on: conn).wait()
        let user = User(id: nil, name: "Tanner", pet: Pet(name: "Ziz"))
        _ = try user.save(on: conn).wait()
        let users = try User.query(on: conn).all().wait()

        XCTAssertEqual(users[0].id, 1)
        XCTAssertEqual(users[0].name, "Tanner")
        XCTAssertEqual(users[0].pet.name, "Ziz")
    }

    func testContains() throws {
        try benchmarker.benchmarkContains_withSchema()
    }

    func testBugs() throws {
        try benchmarker.benchmarkBugs_withSchema()
    }

    func testGH93() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }

        struct Post: MySQLModel, Migration {
            var id: Int?
            var title: String
            var strap: String
            var content: String
            var category: Int
            var slug: String
            var date: Date

            static func prepare(on connection: MySQLConnection) -> Future<Void> {
                return MySQLDatabase.create(self, on: connection) { builder in
                    builder.field(for: \.id, dataType: .bigInt(), primaryKey: true)
                    builder.field(for: \.title)
                    builder.field(for: \.strap)
                    builder.field(for: \.content, dataType: .text())
                    builder.field(for: \.category)
                    builder.field(for: \.slug)
                    builder.field(for: \.date)
                }
            }
        }

        defer { try? Post.revert(on: conn).wait() }
        try Post.prepare(on: conn).wait()

        var post = Post(id: nil, title: "a", strap: "b", content: "c", category: 1, slug: "d", date: .init())
        post = try post.save(on: conn).wait()
        try Post.query(on: conn).delete().wait()
    }

    func testIndexes() throws {
        try benchmarker.benchmarkIndexSupporting_withSchema()
    }

    func testGH61() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }

        let res = try conn.query("SELECT ? as emojis", ["👏🐬💧"]).wait()
        try XCTAssertEqual(String.convertFromMySQLData(res[0].firstValue(forColumn: "emojis")!), "👏🐬💧")
    }

    func testGH76() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }

        struct BoolTest: MySQLModel, Migration {
            var id: Int?
            var bool: Bool
        }

        defer { try? BoolTest.revert(on: conn).wait() }
        try BoolTest.prepare(on: conn).wait()

        var test = BoolTest(id: nil, bool: true)
        test = try test.save(on: conn).wait()
    }

    func testAffectedRows() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }

        _ = try conn.simpleQuery("create table tablea (id INT PRIMARY KEY, cola INT);").wait()
        print(conn.lastMetadata?.affectedRows ?? 0)
        defer { _ = try? conn.simpleQuery("drop table if exists tablea;").wait() }
        _ = try conn.simpleQuery("insert into tablea values (1, 1);").wait()
        print(conn.lastMetadata?.affectedRows ?? 0)
        _ = try conn.simpleQuery("insert ignore into tablea values (1, 2);").wait()
        print(conn.lastMetadata?.affectedRows ?? 0)
    }

    func testLifecycle() throws {
        try benchmarker.benchmarkLifecycle_withSchema()
    }

    static let allTests = [
        ("testSchema", testSchema),
        ("testModels", testModels),
        ("testRelations", testRelations),
        ("testTimestampable", testTimestampable),
        ("testTransactions", testTransactions),
        ("testChunking", testChunking),
        ("testMySQLJoining",testMySQLJoining),
        ("testMySQLCustomSQL", testMySQLCustomSQL),
        ("testMySQLSet", testMySQLSet),
        ("testJSONType", testJSONType),
        ("testContains", testContains),
        ("testBugs", testBugs),
        ("testGH93", testGH93),
        ("testIndexes", testIndexes),
        ("testGH61", testGH61),
        ("testGH76", testGH76),
        ("testLifecycle", testLifecycle),
    ]
}

struct A: MySQLModel {
    static let entity = "tablea"
    var id: Int?
    var cola: Int
}
struct B: MySQLModel {
    static let entity = "tableb"
    var id: Int?
    var colb: Int
}
struct C: MySQLModel {
    static let entity = "tablec"
    var id: Int?
    var colc: Int
}

struct User: MySQLModel, Migration {
    var id: Int?
    var name: String
    var pet: Pet
}

struct Pet: MySQLJSONType {
    var name: String
}
