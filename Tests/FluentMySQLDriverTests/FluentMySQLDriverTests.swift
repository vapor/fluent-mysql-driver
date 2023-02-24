import NIO
import FluentBenchmark
import FluentMySQLDriver
import SQLKit
import XCTest
import Logging
import MySQLKit
import MySQLNIO
import NIOSSL

final class FluentMySQLDriverTests: XCTestCase {
//    func testAll() throws { try self.benchmarker.testAll() }
    func testAggregate() throws { try self.benchmarker.testAggregate() }
    func testArray() throws { try self.benchmarker.testArray() }
    func testBatch() throws { try self.benchmarker.testBatch() }
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

    func testDatabaseError() throws {
        let sql = (self.db as! SQLDatabase)
        do {
            try sql.raw("asdf").run().wait()
        } catch let error as DatabaseError where error.isSyntaxError {
            // pass
        } catch {
            XCTFail("\(error)")
        }
        do {
            try sql.create(table: "foo").column("name", type: .text, .unique).run().wait()
            try sql.insert(into: "foo").columns("name").values("bar").run().wait()
            try sql.insert(into: "foo").columns("name").values("bar").run().wait()
        } catch let error as DatabaseError where error.isConstraintFailure {
            // pass
        } catch {
            XCTFail("\(error)")
        }
        do {
            try self.mysql.withConnection { conn in
                conn.close().flatMap {
                    conn.sql().insert(into: "foo").columns("name").values("bar").run()
                }
            }.wait()
        } catch let error as DatabaseError where error.isConnectionClosed {
            // pass
        } catch let error {
            let error = error
            XCTFail("\(error)")
        }
    }

    func testClarityModel() throws {
        final class Clarity: Model {
            static let schema = "clarities"

            @ID(custom: .id, generatedBy: .database)
            var id: Int?

            @Field(key: "at")
            var at: Date

            @Field(key: "cloud_condition")
            var cloudCondition: Int

            @Field(key: "wind_condition")
            var windCondition: Int

            @Field(key: "rain_condition")
            var rainCondition: Int

            @Field(key: "day_condition")
            var daylightCondition: Int

            @Field(key: "sky_temperature")
            var skyTemperature: Double?

            @Field(key: "sensor_temperature")
            var sensorTemperature: Double?

            @Field(key: "ambient_temperature")
            var ambientTemperature: Double

            @Field(key: "dewpoint_temperature")
            var dewpointTemperature: Double

            @Field(key: "wind_speed")
            var windSpeed: Double?

            @Field(key: "humidity")
            var humidity: Double

            @Field(key: "daylight")
            var daylight: Int

            @Field(key: "rain")
            var rain: Bool

            @Field(key: "wet")
            var wet: Bool

            @Field(key: "heater")
            var heater: Double

            @Field(key: "close_requested")
            var closeRequested: Bool

            init() { }
        }

        struct CreateClarity: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("clarities")
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

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("clarities").delete()
            }
        }

        defer { try? CreateClarity().revert(on: self.db).wait() }
        try CreateClarity().prepare(on: self.db).wait()

        let now = Date()
        do {
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
            try clarity.create(on: self.db).wait()
        }
        do {
            let clarity = try Clarity.query(on: self.db).first().wait()!
            XCTAssertEqual(clarity.at.description, now.description)
            XCTAssertEqual(clarity.cloudCondition, 1)
            XCTAssertEqual(clarity.windCondition, 2)
            XCTAssertEqual(clarity.rainCondition, 3)
            XCTAssertEqual(clarity.daylightCondition, 4)
            XCTAssertEqual(clarity.skyTemperature, nil)
            XCTAssertEqual(clarity.sensorTemperature, nil)
            XCTAssertEqual(clarity.ambientTemperature, 20.0)
            XCTAssertEqual(clarity.dewpointTemperature, -3.0)
            XCTAssertEqual(clarity.windSpeed, nil)
            XCTAssertEqual(clarity.humidity, 59.1)
            XCTAssertEqual(clarity.daylight, 12)
            XCTAssertEqual(clarity.rain, false)
            XCTAssertEqual(clarity.wet, true)
            XCTAssertEqual(clarity.heater, 10)
            XCTAssertEqual(clarity.closeRequested, false)
        }
    }

    func testBoolFilter() throws {
        final class Clarity: Model {
            static let schema = "clarities"

            @ID(custom: .id, generatedBy: .database)
            var id: Int?

            @Field(key: "rain")
            var rain: Bool

            init() { }

            init(rain: Bool) {
                self.rain = rain
            }
        }

        struct CreateClarity: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("clarities")
                    .field("id", .int, .identifier(auto: true))
                    .field("rain", .bool, .required)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("clarities").delete()
            }
        }

        defer { try? CreateClarity().revert(on: self.db).wait() }
        try CreateClarity().prepare(on: self.db).wait()

        let trueValue = Clarity(rain: true)
        let falseValue = Clarity(rain: false)

        try trueValue.save(on: self.db).wait()
        try falseValue.save(on: self.db).wait()

        try XCTAssertEqual(Clarity.query(on: self.db).count().wait(), 2)
        try XCTAssertEqual(
            Clarity.query(on: self.db).filter(\.$rain == true).first().wait()?.id,
            trueValue.id
        )
        try  XCTAssertEqual(
            Clarity.query(on: self.db).filter(\.$rain == false).first().wait()?.id,
            falseValue.id
        )
    }

    func testDateDecoding() throws {
        final class Clarity: Model {
            static let schema = "clarities"

            @ID(custom: .id, generatedBy: .database)
            var id: Int?

            @Field(key: "date")
            var date: Date

            init() { }

            init(date: Date) {
                self.date = date
            }
        }

        struct CreateClarity: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("clarities")
                    .field("id", .int, .identifier(auto: true))
                    .field("date", .date, .required)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("clarities").delete()
            }
        }

        defer { try? CreateClarity().revert(on: self.db).wait() }
        try CreateClarity().prepare(on: self.db).wait()

        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        formatter.dateFormat = "yyyy-MM-dd"

        let firstDate = formatter.date(from: "2020-01-01")!
        let secondDate = formatter.date(from: "1994-05-23")!
        let trueValue = Clarity(date: firstDate)
        let falseValue = Clarity(date: secondDate)

        try trueValue.save(on: self.db).wait()
        try falseValue.save(on: self.db).wait()

        let receivedModels = try Clarity.query(on: self.db).all().wait()
        XCTAssertEqual(receivedModels.count, 2)
        XCTAssertEqual(receivedModels[0].date, firstDate)
        XCTAssertEqual(receivedModels[1].date, secondDate)
    }

    func testChar36UUID() throws {
        final class Foo: Model {
            static let schema = "foos"

            @ID(key: .id)
            var id: UUID?

            @Field(key: "bar")
            var _bar: String

            var bar: UUID {
                get {
                    UUID(uuidString: self._bar)!
                }
                set {
                    self._bar = newValue.uuidString
                }
            }

            init() { }

            init(id: UUID? = nil, bar: UUID) {
                self.id = id
                self.bar = bar
            }
        }

        try self.db.schema("foos")
            .id()
            .field("bar", .sql(raw: "CHAR(36)"), .required)
            .create()
            .wait()
        defer {
            try! self.db.schema("foos").delete().wait()
        }

        let foo = Foo(bar: .init())
        try foo.create(on: self.db).wait()
        XCTAssertNotNil(foo.id)

        let fetched = try Foo.find(foo.id, on: self.db).wait()
        XCTAssertEqual(fetched?.bar, foo.bar)
    }

    var benchmarker: FluentBenchmarker {
        return .init(databases: self.dbs)
    }
    var eventLoopGroup: EventLoopGroup!
    var threadPool: NIOThreadPool!
    var dbs: Databases!
    var db: Database {
        self.benchmarker.database
    }
    var mysql: MySQLDatabase {
        self.db as! MySQLDatabase
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.threadPool = NIOThreadPool(numberOfThreads: System.coreCount)
        self.dbs = Databases(threadPool: threadPool, on: self.eventLoopGroup)

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
        try self.threadPool.syncShutdownGracefully()
        try self.eventLoopGroup.syncShutdownGracefully()
        
        try super.tearDownWithError()
    }
}

extension DatabaseID {
    static let a = DatabaseID(string: "mysql_a")
    static let b = DatabaseID(string: "mysql_b")
}

func env(_ name: String) -> String? {
    return ProcessInfo.processInfo.environment[name]
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .debug
        return handler
    }
    return true
}()
