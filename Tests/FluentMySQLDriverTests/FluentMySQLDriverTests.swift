import NIO
import FluentBenchmark
import FluentSQL
@testable import FluentMySQLDriver
import SQLKit
import XCTest
import Logging
import MySQLKit
import MySQLNIO
import NIOSSL

func XCTAssertEqualAsync<T>(
    _ expression1: @autoclosure () async throws -> T,
    _ expression2: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line
) async where T: Equatable {
    do {
        let expr1 = try await expression1(), expr2 = try await expression2()
        return XCTAssertEqual(expr1, expr2, message(), file: file, line: line)
    } catch {
        return XCTAssertEqual(try { () -> Bool in throw error }(), false, message(), file: file, line: line)
    }
}

func XCTAssertNilAsync(
    _ expression: @autoclosure () async throws -> Any?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line
) async {
    do {
        let result = try await expression()
        return XCTAssertNil(result, message(), file: file, line: line)
    } catch {
        return XCTAssertNil(try { throw error }(), message(), file: file, line: line)
    }
}

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line,
    _ callback: (any Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTAssertThrowsError({}(), message(), file: file, line: line, callback)
    } catch {
        XCTAssertThrowsError(try { throw error }(), message(), file: file, line: line, callback)
    }
}

final class FluentMySQLDriverTests: XCTestCase {
    func testAggregate() throws { try self.benchmarker.testAggregate() }
    func testArray() throws { try self.benchmarker.testArray() }
    func testBatch() throws { try self.benchmarker.testBatch() }
    func testChild() throws { try self.benchmarker.testChild() }
    func testChildren() throws { try self.benchmarker.testChildren() }
    func testCodable() throws { try self.benchmarker.testCodable() }
    func testChunk() throws { try self.benchmarker.testChunk() }
    func testCompositeID() throws { try self.benchmarker.testCompositeID() }
    func testCRUD() throws { try self.benchmarker.testCRUD() }
    func testEagerLoad() throws { try self.benchmarker.testEagerLoad() }
    func testEnum() throws { try self.benchmarker.testEnum() }
    func testFilter() throws { try self.benchmarker.testFilter() }
    func testGroup() throws { try self.benchmarker.testGroup() }
    func testID() throws { try self.benchmarker.testID() }
    func testJoin() throws { try self.benchmarker.testJoin() }
    func testMiddleware() throws { try self.benchmarker.testMiddleware() }
    func testMigrator() throws { try self.benchmarker.testMigrator() }
    func testModel() throws { try self.benchmarker.testModel() }
    func testOptionalParent() throws { try self.benchmarker.testOptionalParent() }
    func testPagination() throws { try self.benchmarker.testPagination() }
    func testParent() throws { try self.benchmarker.testParent() }
    func testPerformance() throws { try self.benchmarker.testPerformance() }
    func testRange() throws { try self.benchmarker.testRange() }
    func testSchema() throws { try self.benchmarker.testSchema() }
    func testSet() throws { try self.benchmarker.testSet() }
    func testSiblings() throws { try self.benchmarker.testSiblings() }
    func testSoftDelete() throws { try self.benchmarker.testSoftDelete() }
    func testSort() throws { try self.benchmarker.testSort() }
    func testSQL() throws { try self.benchmarker.testSQL() }
    func testTimestamp() throws { try self.benchmarker.testTimestamp() }
    func testTransaction() throws { try self.benchmarker.testTransaction() }
    func testUnique() throws { try self.benchmarker.testUnique() }

    func testDatabaseError() async throws {
        let sql = (self.db as! any SQLDatabase)
        await XCTAssertThrowsErrorAsync(try await sql.raw("asdf").run()) {
            XCTAssertTrue(($0 as? any DatabaseError)?.isSyntaxError ?? false, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isConstraintFailure ?? true, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isConnectionClosed ?? true, "\(String(reflecting: $0))")
        }
        try await sql.drop(table: "foo").ifExists().run()
        try await sql.create(table: "foo").column("name", type: .text, .unique).run()
        try await sql.insert(into: "foo").columns("name").values("bar").run()
        await XCTAssertThrowsErrorAsync(try await sql.insert(into: "foo").columns("name").values("bar").run()) {
            XCTAssertTrue(($0 as? any DatabaseError)?.isConstraintFailure ?? false, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isSyntaxError ?? true, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isConnectionClosed ?? true, "\(String(reflecting: $0))")
        }
        await XCTAssertThrowsErrorAsync(try await self.mysql.withConnection { conn in
            conn.close().flatMap {
                conn.sql().insert(into: "foo").columns("name").values("bar").run()
            }
        }.get()) {
            XCTAssertTrue(($0 as? any DatabaseError)?.isConnectionClosed ?? false, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isSyntaxError ?? true, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isConstraintFailure ?? true, "\(String(reflecting: $0))")
        }
    }

    func testClarityModel() async throws {
        final class Clarity: Model, @unchecked Sendable {
            static let schema = "clarities"

            @ID(custom: .id, generatedBy: .database) var id: Int?
            @Field(key: "at") var at: Date
            @Field(key: "cloud_condition") var cloudCondition: Int
            @Field(key: "wind_condition") var windCondition: Int
            @Field(key: "rain_condition") var rainCondition: Int
            @Field(key: "day_condition") var daylightCondition: Int
            @Field(key: "sky_temperature") var skyTemperature: Double?
            @Field(key: "sensor_temperature") var sensorTemperature: Double?
            @Field(key: "ambient_temperature") var ambientTemperature: Double
            @Field(key: "dewpoint_temperature") var dewpointTemperature: Double
            @Field(key: "wind_speed") var windSpeed: Double?
            @Field(key: "humidity") var humidity: Double
            @Field(key: "daylight") var daylight: Int
            @Field(key: "rain") var rain: Bool
            @Field(key: "wet") var wet: Bool
            @Field(key: "heater") var heater: Double
            @Field(key: "close_requested") var closeRequested: Bool

            init() {}
        }

        struct CreateClarity: AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema("clarities")
                    .field("id", .int, .identifier(auto: true))
                    .field("at", .datetime, .required)
                    .field("cloud_condition", .int, .required)
                    .field("wind_condition", .int, .required)
                    .field("rain_condition", .int, .required)
                    .field("day_condition", .int, .required)
                    .field("sky_temperature", .float)
                    .field("sensor_temperature", .float)
                    .field("ambient_temperature", .float, .required)
                    .field("dewpoint_temperature", .float, .required)
                    .field("wind_speed", .float)
                    .field("humidity", .double, .required)
                    .field("daylight", .int, .required)
                    .field("rain", .bool, .required)
                    .field("wet", .bool, .required)
                    .field("heater", .float, .required)
                    .field("close_requested", .bool, .required)
                    .create()
            }

            func revert(on database: any Database) async throws {
                try await database.schema("clarities").delete()
            }
        }

        try await CreateClarity().prepare(on: self.db)

        do {
            let now = Date()
            let clarity = Clarity()
            clarity.at = now
            clarity.cloudCondition = 1
            clarity.windCondition = 2
            clarity.rainCondition = 3
            clarity.daylightCondition = 4
            clarity.skyTemperature = nil
            clarity.sensorTemperature = nil
            clarity.ambientTemperature = 20.0
            clarity.dewpointTemperature = -3.0
            clarity.windSpeed = nil
            clarity.humidity = 59.1
            clarity.daylight = 12
            clarity.rain = false
            clarity.wet = true
            clarity.heater = 10
            clarity.closeRequested = false
            try await clarity.create(on: self.db)

            let dbClarity = try await Clarity.query(on: self.db).first()
            XCTAssertEqual(dbClarity?.at.description, now.description)
            XCTAssertEqual(dbClarity?.cloudCondition, 1)
            XCTAssertEqual(dbClarity?.windCondition, 2)
            XCTAssertEqual(dbClarity?.rainCondition, 3)
            XCTAssertEqual(dbClarity?.daylightCondition, 4)
            XCTAssertEqual(dbClarity?.skyTemperature, nil)
            XCTAssertEqual(dbClarity?.sensorTemperature, nil)
            XCTAssertEqual(dbClarity?.ambientTemperature, 20.0)
            XCTAssertEqual(dbClarity?.dewpointTemperature, -3.0)
            XCTAssertEqual(dbClarity?.windSpeed, nil)
            XCTAssertEqual(dbClarity?.humidity, 59.1)
            XCTAssertEqual(dbClarity?.daylight, 12)
            XCTAssertEqual(dbClarity?.rain, false)
            XCTAssertEqual(dbClarity?.wet, true)
            XCTAssertEqual(dbClarity?.heater, 10)
            XCTAssertEqual(dbClarity?.closeRequested, false)
        } catch {
            try? await CreateClarity().revert(on: self.db)
            throw error
        }
        try await CreateClarity().revert(on: self.db)
    }

    func testBoolFilter() async throws {
        final class Clarity: Model, @unchecked Sendable {
            static let schema = "clarities"

            @ID(custom: .id, generatedBy: .database)
            var id: Int?

            @Field(key: "rain")
            var rain: Bool

            init() {}

            init(rain: Bool) {
                self.rain = rain
            }
        }

        struct CreateClarity: AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema("clarities")
                    .field("id", .int, .identifier(auto: true))
                    .field("rain", .bool, .required)
                    .create()
            }

            func revert(on database: any Database) async throws {
                try await database.schema("clarities").delete()
            }
        }

        try await CreateClarity().prepare(on: self.db)

        do {
            let trueValue = Clarity(rain: true)
            let falseValue = Clarity(rain: false)

            try await trueValue.save(on: self.db)
            try await falseValue.save(on: self.db)

            await XCTAssertEqualAsync(try await Clarity.query(on: self.db).count(), 2)
            await XCTAssertEqualAsync(try await Clarity.query(on: self.db).filter(\.$rain == true).first()?.id, trueValue.id)
            await XCTAssertEqualAsync(try await Clarity.query(on: self.db).filter(\.$rain == false).first()?.id, falseValue.id)
        } catch {
            try? await CreateClarity().revert(on: self.db)
            throw error
        }
        try await CreateClarity().revert(on: self.db)
    }

    func testDateDecoding() async throws {
        final class Clarity: Model, @unchecked Sendable {
            static let schema = "clarities"

            @ID(custom: .id, generatedBy: .database)
            var id: Int?

            @Field(key: "date")
            var date: Date

            init() {}

            init(date: Date) {
                self.date = date
            }
        }

        struct CreateClarity: AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema("clarities")
                    .field("id", .int, .identifier(auto: true))
                    .field("date", .date, .required)
                    .create()
            }

            func revert(on database: any Database) async throws {
                try await database.schema("clarities").delete()
            }
        }

        try await CreateClarity().prepare(on: self.db)
        
        do {
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)!
            formatter.dateFormat = "yyyy-MM-dd"

            let firstDate = formatter.date(from: "2020-01-01")!
            let secondDate = formatter.date(from: "1994-05-23")!
            let trueValue = Clarity(date: firstDate)
            let falseValue = Clarity(date: secondDate)

            try await trueValue.save(on: self.db)
            try await falseValue.save(on: self.db)

            let receivedModels = try await Clarity.query(on: self.db).all()
            XCTAssertEqual(receivedModels.count, 2)
            XCTAssertEqual(receivedModels[0].date, firstDate)
            XCTAssertEqual(receivedModels[1].date, secondDate)
        } catch {
            try? await CreateClarity().revert(on: self.db)
            throw error
        }
        try await CreateClarity().revert(on: self.db)
    }

    func testChar36UUID() async throws {
        final class Foo: Model, @unchecked Sendable {
            static let schema = "foos"

            @ID(key: .id)
            var id: UUID?

            @Field(key: "bar")
            var _bar: String

            var bar: UUID {
                get { UUID(uuidString: self._bar)! }
                set { self._bar = newValue.uuidString }
            }

            init() {}

            init(id: UUID? = nil, bar: UUID) {
                self.id = id
                self.bar = bar
            }
        }
        
        try await self.mysql.sql().drop(table: "foos").ifExists().run()
        try await self.db.schema("foos")
            .id()
            .field("bar", .sql(raw: "CHAR(36)"), .required)
            .create()

        do {
            let foo = Foo(bar: .init())
            try await foo.create(on: self.db)
            XCTAssertNotNil(foo.id)

            let fetched = try await Foo.find(foo.id, on: self.db)
            XCTAssertEqual(fetched?.bar, foo.bar)
        } catch {
            try? await self.db.schema("foos").delete()
        }
        try await self.db.schema("foos").delete()
    }
    
    func testBindingEncodeFailures() async throws {
        struct FailingDataType: Codable, MySQLDataConvertible, Equatable {
            init() {}
            init?(mysqlData: MySQLData) { nil }
            var mysqlData: MySQLData? { nil }
        }
        final class M: Model, @unchecked Sendable {
            static let schema = "s"
            @ID var id
            @Field(key: "f") var f: FailingDataType
            init() { self.f = .init() }
        }
        await XCTAssertThrowsErrorAsync(try await M.query(on: self.db).filter(\.$f == .init()).all()) {
            XCTAssertNotNil($0 as? EncodingError, String(reflecting: $0))
        }
        
        await XCTAssertThrowsErrorAsync(try await self.db.schema("s").field("f", .custom(SQLBind(FailingDataType()))).create()) {
            XCTAssertNotNil($0 as? EncodingError, String(reflecting: $0))
        }
    }
    
    func testMiscSQLDatabaseSupport() async throws {
        XCTAssertEqual((self.db as? any SQLDatabase)?.queryLogLevel, .debug)
        await XCTAssertEqualAsync(try await (self.db as? any SQLDatabase)?.withSession { $0.dialect.name }, (self.db as? any SQLDatabase)?.dialect.name)
        
        final class M: Model, @unchecked Sendable {
            static let schema = "s"
            @ID var id
            @OptionalField(key: "k") var k: Int?
            init() {}
        }
        try await (self.db as? any SQLDatabase)?.drop(table: M.schema).ifExists().run()
        try await (self.db as? any SQLDatabase)?.create(table: M.schema).column("id", type: .custom(SQLRaw("varbinary(16)")), .primaryKey(autoIncrement: false)).run()
        await XCTAssertNilAsync(try await (self.db as? any SQLDatabase)?.select().column("id").from(M.schema).first(decodingFluent: M.self)?.k)
        try await (self.db as? any SQLDatabase)?.drop(table: M.schema).run()
    }
    
    func testLastInsertRow() {
        XCTAssertNotNil(LastInsertRow(lastInsertID: 0, customIDKey: nil).description)
        let row = LastInsertRow(lastInsertID: nil, customIDKey: nil)
        XCTAssertNotNil(row.description)
        XCTAssertEqual(row.schema("").description, row.description)
        XCTAssertFalse(try row.decodeNil(.id))
        XCTAssertThrowsError(try row.decode(.id, as: String.self)) {
            guard case .typeMismatch(_, _) = $0 as? DecodingError else {
                return XCTFail("Expected DecodingError.typeMismatch, but got \(String(reflecting: $0))")
            }
        }
        XCTAssertThrowsError(try row.decode("foo", as: Int.self)) {
            guard case .keyNotFound(let key, _) = $0 as? DecodingError else {
                return XCTFail("Expected DecodingError.keyNotFound, but got \(String(reflecting: $0))")
            }
            XCTAssertEqual(key.stringValue, "foo")
        }
        XCTAssertThrowsError(try row.decode(.id, as: Int.self)) {
            guard case .valueNotFound(_, _) = $0 as? DecodingError else {
                return XCTFail("Expected DecodingError.valueNotFound, but got \(String(reflecting: $0))")
            }
        }
    }
    
    func testNeverInvokedDatabaseOutputCodePath() async throws {
        final class M: Model, @unchecked Sendable {
            static let schema = "s"
            @ID var id
            init() {}
        }
        try await (self.db as? any SQLDatabase)?.drop(table: M.schema).ifExists().run()
        try await self.db.schema(M.schema).id().create()
        do {
            try await M().create(on: self.db)
            try await self.db.execute(query: M.query(on: self.db).field(\.$id).query, onOutput: { XCTAssert((try? $0.decodeNil("not a real key")) ?? false) }).get()
        } catch {
            try? await self.db.schema(M.schema).delete()
            throw error
        }
        try await self.db.schema(M.schema).delete()
    }
    
    func testMiscConfigMethods() {
        XCTAssertNotNil(try DatabaseConfigurationFactory.mysql(unixDomainSocketPath: "/", username: "", password: ""))
        XCTAssertNoThrow(try DatabaseConfigurationFactory.mysql(url: "mysql://user@host/db"))
        XCTAssertThrowsError(try DatabaseConfigurationFactory.mysql(url: "notmysql://foo@bar"))
        XCTAssertThrowsError(try DatabaseConfigurationFactory.mysql(url: "not$a$valid$url://"))
        XCTAssertNoThrow(try DatabaseConfigurationFactory.mysql(url: URL(string: "mysql://user@host/db")!))
        XCTAssertThrowsError(try DatabaseConfigurationFactory.mysql(url: URL(string: "notmysql://foo@bar")!))
        XCTAssertEqual(DatabaseID.mysql.string, "mysql")
    }

    var benchmarker: FluentBenchmarker { .init(databases: self.dbs) }
    var eventLoopGroup: any EventLoopGroup { MultiThreadedEventLoopGroup.singleton }
    var threadPool: NIOThreadPool { NIOThreadPool.singleton }
    var dbs: Databases!
    var db: any Database { self.benchmarker.database }
    var mysql: any MySQLDatabase { self.db as! any MySQLDatabase }

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        XCTAssert(isLoggingConfigured)
        self.dbs = Databases(threadPool: self.threadPool, on: self.eventLoopGroup)

        var tls = TLSConfiguration.makeClientConfiguration()
        tls.certificateVerification = .none
        let databaseA = env("MYSQL_DATABASE_A") ?? "test_database"
        let databaseB = env("MYSQL_DATABASE_B") ?? "test_database"
        self.dbs.use(.mysql(
            hostname: env("MYSQL_HOSTNAME_A") ?? "localhost",
            port: env("MYSQL_PORT_A").flatMap(Int.init) ?? 3306,
            username: env("MYSQL_USERNAME_A") ?? "test_username",
            password: env("MYSQL_PASSWORD_A") ?? "test_password",
            database: databaseA,
            tlsConfiguration: tls,
            connectionPoolTimeout: .seconds(10)
        ), as: .a)

        self.dbs.use(.mysql(
            hostname: env("MYSQL_HOSTNAME_B") ?? "localhost",
            port: env("MYSQL_PORT_B").flatMap(Int.init) ?? 3306,
            username: env("MYSQL_USERNAME_B") ?? "test_username",
            password: env("MYSQL_PASSWORD_B") ?? "test_password",
            database: databaseB,
            tlsConfiguration: tls,
            connectionPoolTimeout: .seconds(10)
        ), as: .b)
    }
    
    override func tearDownWithError() throws {
        self.dbs.shutdown()
        
        try super.tearDownWithError()
    }
}

extension DatabaseID {
    static let a = DatabaseID(string: "mysql_a")
    static let b = DatabaseID(string: "mysql_b")
}

func env(_ name: String) -> String? {
    ProcessInfo.processInfo.environment[name]
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { .init(rawValue: $0) } ?? .info
        return handler
    }
    return true
}()
