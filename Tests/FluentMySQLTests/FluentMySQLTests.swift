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
    var database: MySQLDatabase!
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
        let setupConn = try! setupDatabase.makeConnection(on: loop).await(on: loop)

        _ = try? setupConn.administrativeQuery("CREATE DATABASE \(testDatabase)").await(on: loop)
        didCreateDatabase = true
        setupConn.close()

        self.database = MySQLDatabase(hostname: testHostname, user: testUsername, password: testPassword, database: testDatabase)
        self.benchmarker = Benchmarker(database, on: loop, onFail: XCTFail)
    }
    
    override func tearDown() {
        // This extra protection is probably unnecessary, but it's here anyway
        // to ensure that we're not relying on `XCTestCase`'s semantics to
        // prevent accidental drops.
        if didCreateDatabase {
            let setupDatabase = MySQLDatabase(hostname: testHostname, user: testUsername, password: testPassword, database: "")
            let teardownConn = try! setupDatabase.makeConnection(on: loop).await(on: loop)
            
            try! teardownConn.administrativeQuery("DROP DATABASE IF EXISTS \(testDatabase)").await(on: loop)
            teardownConn.close()
        }
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

    func testReferences() throws {
        let conn = try database.makeConnection(on: loop).await(on: loop)
        // Prep tables
        try Pet.prepare(on: conn).await(on: loop)
        try User.prepare(on: conn).await(on: loop)
        // Save Pet
        let pet = Pet(id: 64, name: "Snuffles")
        _ = try pet.create(on: conn).await(on: loop)
        // Save User with a ref to previously saved Pet
        let user = User(id: nil, name: "Morty", petId: pet.id!)
        _ = try user.create(on: conn).await(on: loop)

        if let fetched = try User.query(on: conn).first().await(on: loop) {
            XCTAssertEqual(user.id, fetched.id)
            XCTAssertEqual(user.name, fetched.name)
            XCTAssertEqual(user.petId, fetched.petId)
        } else {
            XCTFail()
        }
        try User.revert(on: conn).await(on: loop)
        try Pet.revert(on: conn).await(on: loop)
        conn.close()
    }

    func testForeignKeyIndexCount() throws {
        let conn = try database.makeConnection(on: loop).await(on: loop)

        // Prep tables
        try Pet.prepare(on: conn).await(on: loop)
        try User.prepare(on: conn).await(on: loop)

        let query = "select COUNT(*) as resultCount from information_schema.KEY_COLUMN_USAGE where table_schema = '\(testDatabase)' and table_name = '\(User.entity)' and constraint_name != 'PRIMARY'"

        let fetched = try conn.all(CountResult.self, in: query).await(on: loop)
        if let fetchedFirst = fetched.first {
            XCTAssertEqual(1, fetchedFirst.resultCount)
        } else {
            XCTFail()
        }

        try User.revert(on: conn).await(on: loop)
        try Pet.revert(on: conn).await(on: loop)
        conn.close()
    }

    static let allTests = [
        ("testSchema", testSchema),
        ("testModels", testModels),
        ("testRelations", testRelations),
        ("testTimestampable", testTimestampable),
        ("testTransactions", testTransactions),
        ("testChunking", testChunking),
        ("testReferences", testReferences),
        ("testForeignKeyIndexCount", testForeignKeyIndexCount),
    ]
}

final class Pet: MySQLModel, Migration {
    var id: Int?
    var name: String

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

final class CountResult: Codable {
    var resultCount: Int
}

final class User: MySQLModel, Migration {
    var id: Int?
    var name: String
    var petId: Int

    init(id: Int? = nil, name: String, petId: Int) {
        self.id = id
        self.name = name
        self.petId = petId
    }

    static func prepare(on connection: MySQLDatabase.Connection) -> Future<Void> {
        return Database.create(self, on: connection, closure: { builder in
            try addProperties(to: builder)
            builder.addReference(from: \.petId, to: \Pet.id, actions: .update)
        })
    }
}
