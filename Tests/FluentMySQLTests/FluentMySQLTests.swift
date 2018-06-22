import FluentBenchmark
import FluentMySQL
import Fluent
import XCTest

class FluentMySQLTests: XCTestCase {
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

    func testBenchmark() throws {
        try benchmarker.runAll()
    }
    
    func testVersion() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        
        let version = try conn.simpleQuery("SELECT version();").wait()
        print(version)
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

        let builder = A.query(on: conn)
        builder.query.predicate &= MySQLExpression.binary("cola", .equal, .literal(.null))
        try XCTAssertEqual(builder.all().wait().count, 0)
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
                    builder.field(for: \.id)
                    builder.field(for: \.title)
                    builder.field(for: \.strap)
                    builder.field(for: \.content, type: .varchar(64))
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

        let res = try conn.raw("SELECT ? as emojis").bind("👏🐬💧").all().wait()
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
    
    func testCreateOrIgnore() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        try User.prepare(on: conn).wait()
        defer { try! User.revert(on: conn).wait() }

        let a = User(id: 1, name: "A", pet: .init(name: "A"))
        let b = User(id: 1, name: "B", pet: .init(name: "B"))

        _ = try a.create(orIgnore: true, on: conn).wait()
        let resa = conn.lastMetadata?.affectedRows
        _ = try b.create(orIgnore: true, on: conn).wait()
        let resb = conn.lastMetadata?.affectedRows

        XCTAssertNotEqual(resa, resb)
    }

    func testCreateOrUpdate() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        try User.prepare(on: conn).wait()
        defer { try! User.revert(on: conn).wait() }

        let a = User(id: 1, name: "A", pet: .init(name: "A"))
        let b = User(id: 1, name: "B", pet: .init(name: "B"))

        _ = try a.create(orUpdate: true, on: conn).wait()
        _ = try b.create(orUpdate: true, on: conn).wait()

        let c = try User.find(1, on: conn).wait()
        XCTAssertEqual(c?.name, "B")
    }

    func testContains() throws {
        struct User: MySQLModel, MySQLMigration {
            var id: Int?
            var name: String
            var age: Int
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try User.prepare(on: conn).wait()
        defer { try! User.revert(on: conn).wait() }
        
        // create
        let tanner1 = User(id: nil, name: "tanner", age: 23)
        _ = try tanner1.save(on: conn).wait()
        let tanner2 = User(id: nil, name: "ner", age: 23)
        _ = try tanner2.save(on: conn).wait()
        let tanner3 = User(id: nil, name: "tan", age: 23)
        _ = try tanner3.save(on: conn).wait()
        
        let tas = try User.query(on: conn).filter(\.name, .like, "ta%").count().wait()
        if tas != 2 {
            XCTFail("tas == \(tas)")
        }
        let ers = try User.query(on: conn).filter(\.name ~= "er").count().wait()
        if ers != 2 {
            XCTFail("ers == \(tas)")
        }
        let annes = try User.query(on: conn).filter(\.name ~~ "anne").count().wait()
        if annes != 1 {
            XCTFail("annes == \(tas)")
        }
        let ns = try User.query(on: conn).filter(\.name ~~ "n").count().wait()
        if ns != 3 {
            XCTFail("ns == \(tas)")
        }
        
        let nertan = try User.query(on: conn).filter(\.name ~~ ["ner", "tan"]).count().wait()
        if nertan != 2 {
            XCTFail("nertan == \(tas)")
        }
        
        let notner = try User.query(on: conn).filter(\.name !~ ["ner"]).count().wait()
        if notner != 2 {
            XCTFail("nertan == \(tas)")
        }
    }
    
    func testSort() throws {
        struct User: MySQLModel, MySQLMigration, Equatable {
            var id: Int?
            var name: String
            var age: Int
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try User.prepare(on: conn).wait()
        defer { try! User.revert(on: conn).wait() }
        
        var a = User(id: nil, name: "A", age: 90)
        a = try a.save(on: conn).wait()
        var z = User(id: nil, name: "Z", age: 10)
        z = try z.save(on: conn).wait()
        
        let usersByName = try User.query(on: conn).sort(\.name, .descending).all().wait()
        let usersByAge = try User.query(on: conn).sort(\.age, .descending).all().wait()
        XCTAssertNotEqual(usersByName, usersByAge)
    }
    
    func testConcurrentQuery() throws {
        struct User: MySQLModel, MySQLMigration, Equatable {
            var id: Int?
            var name: String
            var age: Int
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try User.prepare(on: conn).wait()
        defer { try! User.revert(on: conn).wait() }
        
        let usersByName = User.query(on: conn).sort(\.name, .descending).all()
        let usersByAge = User.query(on: conn).sort(\.age, .descending).all()
        
        _ = try [usersByAge, usersByName].flatten(on: conn).wait()
    }
    
    func testEmptySubset() throws {
        struct User: MySQLModel, MySQLMigration {
            var id: Int?
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        try User.prepare(on: conn).wait()
        defer { _ = try? User.revert(on: conn).wait() }
        
        let res = try User.query(on: conn).filter(\.id ~~ []).all().wait()
        XCTAssertEqual(res.count, 0)
        _ = try User.query(on: conn).filter(\.id ~~ [1]).all().wait()
        _ = try User.query(on: conn).filter(\.id ~~ [1, 2]).all().wait()
        _ = try User.query(on: conn).filter(\.id ~~ [1, 2, 3]).all().wait()
    }
    
    func testLongName() throws {
        struct Antidisestablishmentarianism: MySQLModel, MySQLMigration {
            var id: Int?
            var antidisestablishmentarianismFoo: String
            var antidisestablishmentarianismBar: String
            
            static func prepare(on conn: MySQLConnection) -> Future<Void> {
                return MySQLDatabase.create(Antidisestablishmentarianism.self, on: conn) { builder in
                    builder.field(for: \.id)
                    builder.field(for: \.antidisestablishmentarianismFoo)
                    builder.field(for: \.antidisestablishmentarianismBar)
                    builder.unique(on: \.antidisestablishmentarianismFoo, \.antidisestablishmentarianismBar)
                }
            }
        }
        
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        try Antidisestablishmentarianism.prepare(on: conn).wait()
        defer { _ = try? Antidisestablishmentarianism.revert(on: conn).wait() }
    }
    
    func testMySQLRawEnum() {
        enum TestEnum: String, MySQLEnumType, CaseIterable {
            static var allCases: [TestEnum] = [.foo, .bar]
            case foo, bar
        }
    }
    
    func testColumnPositioning() throws {
        struct CustomOrder: MySQLModel {
            var id: Int?
            var a: Int
            var b: Int
        }

        struct CreateCustomOrder: MySQLMigration {
            static func prepare(on conn: MySQLConnection) -> Future<Void> {
                return MySQLDatabase.create(CustomOrder.self, on: conn) { builder in
                    builder.field(for: \.id)
                    builder.field(for: \.a)
                }
            }
            
            static func revert(on conn: MySQLConnection) -> Future<Void> {
                return MySQLDatabase.delete(CustomOrder.self, on: conn)
            }
        }
        
        struct AddColumnBToCustomOrder: MySQLMigration {
            static func prepare(on conn: MySQLConnection) -> Future<Void> {
                return MySQLDatabase.update(CustomOrder.self, on: conn) { builder in
                    builder.field(for: \.b)
                    builder.order(\.b, after: \.id)
                }
            }
            
            static func revert(on conn: MySQLConnection) -> Future<Void> {
                return MySQLDatabase.update(CustomOrder.self, on: conn) { builder in
                    builder.deleteField(for: \.b)
                }
            }
        }

        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        defer { _ = try? CreateCustomOrder.revert(on: conn).wait() }
        try CreateCustomOrder.prepare(on: conn).wait()
        defer { _ = try? AddColumnBToCustomOrder.revert(on: conn).wait() }
        try AddColumnBToCustomOrder.prepare(on: conn).wait()
        print("hi")
    }
    
    static let allTests = [
        ("testBenchmark", testBenchmark),
        ("testMySQLJoining",testMySQLJoining),
        ("testMySQLCustomSQL", testMySQLCustomSQL),
        ("testMySQLSet", testMySQLSet),
        ("testJSONType", testJSONType),
        ("testBugs", testBugs),
        ("testGH93", testGH93),
        ("testIndexes", testIndexes),
        ("testGH61", testGH61),
        ("testGH76", testGH76),
        ("testContains", testContains),
        ("testConcurrentQuery", testConcurrentQuery),
        ("testEmptySubset", testEmptySubset),
        ("testLongName", testLongName),
        ("testCreateOrUpdate", testCreateOrUpdate),
        ("testCreateOrIgnore", testCreateOrIgnore),
        ("testMySQLRawEnum", testMySQLRawEnum),
        ("testColumnPositioning", testColumnPositioning),
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

struct Pet: Codable {
    var name: String
}

final class Parent: MySQLModel, Migration {
    var id: Int?
    var name: String
    
    init(id: Int?, name: String) {
        self.id = id
        self.name = name
    }
}

final class Child: MySQLModel, Migration {
    var id: Int?
    var name: String
    var parentId: Int

    init(id: Int?, name: String, parentId: Int) {
        self.id = id
        self.name = name
        self.parentId = parentId
    }
    
    static func prepare(on connection: MySQLDatabase.Connection) -> Future<Void> {
        return Database.create(self, on: connection, closure: { builder in
            try addProperties(to: builder)
            builder.reference(from: \.parentId, to: \Parent.id)
        })
    }
}
