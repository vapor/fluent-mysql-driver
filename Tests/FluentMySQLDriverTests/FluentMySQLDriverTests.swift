import NIO
import FluentBenchmark
import FluentMySQLDriver
import XCTest
import Logging

final class FluentMySQLDriverTests: XCTestCase {
    func testAll() throws {
        try self.benchmarker.testAll()
    }

    func testCreate() throws {
        try self.benchmarker.testCreate()
    }

    func testRead() throws {
        try self.benchmarker.testRead()
    }

    func testUpdate() throws {
        try self.benchmarker.testUpdate()
    }

    func testDelete() throws {
        try self.benchmarker.testDelete()
    }

    func testEagerLoadChildren() throws {
        try self.benchmarker.testEagerLoadChildren()
    }

    func testEagerLoadParent() throws {
        try self.benchmarker.testEagerLoadParent()
    }

    func testEagerLoadParentJoin() throws {
        try self.benchmarker.testEagerLoadParentJoin()
    }

    func testEagerLoadParentJSON() throws {
        try self.benchmarker.testEagerLoadParentJSON()
    }

    func testEagerLoadOptionalParent() throws {
        try self.benchmarker.testEagerLoadOptionalParent()
    }

    func testEagerLoadOptionalJoinParent() throws {
        try self.benchmarker.testEagerLoadOptionalJoinParent()
    }
    
    func testEagerLoadOptionalChildren() throws {
        try self.benchmarker.testEagerLoadOptionalChildren()
    }

    func testEagerLoadChildrenJSON() throws {
        try self.benchmarker.testEagerLoadChildrenJSON()
    }

    func testMigrator() throws {
        try self.benchmarker.testMigrator()
    }

    func testMigratorError() throws {
        try self.benchmarker.testMigratorError()
    }

    func testJoin() throws {
        try self.benchmarker.testJoin()
    }

    func testBatchCreate() throws {
        try self.benchmarker.testBatchCreate()
    }

    func testBatchUpdate() throws {
        try self.benchmarker.testBatchUpdate()
    }

    func testNestedModel() throws {
        try self.benchmarker.testNestedModel()
    }

    func testAggregates() throws {
        try self.benchmarker.testAggregates()
    }

    func testIdentifierGeneration() throws {
        try self.benchmarker.testIdentifierGeneration()
    }

    func testNullifyField() throws {
        try self.benchmarker.testNullifyField()
    }

    func testChunkedFetch() throws {
        try self.benchmarker.testChunkedFetch()
    }

    func testUniqueFields() throws {
        try self.benchmarker.testUniqueFields()
    }

    func testAsyncCreate() throws {
        try self.benchmarker.testAsyncCreate()
    }

    func testSoftDelete() throws {
        try self.benchmarker.testSoftDelete()
    }

    func testTimestampable() throws {
        try self.benchmarker.testTimestampable()
    }

    func testLifecycleHooks() throws {
        try self.benchmarker.testLifecycleHooks()
    }

    func testSort() throws {
        try self.benchmarker.testSort()
    }

    func testUUIDModel() throws {
        try self.benchmarker.testUUIDModel()
    }

    func testNewModelDecode() throws {
        try self.benchmarker.testNewModelDecode()
    }

    func testSiblingsAttach() throws {
        try self.benchmarker.testSiblingsAttach()
    }

    func testSiblingsEagerLoad() throws {
        try self.benchmarker.testSiblingsEagerLoad()
    }

    func testClarityModel() throws {
        final class Clarity: Model {
            static let schema = "clarities"

            @ID(key: "id")
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

        defer { try? CreateClarity().revert(on: self.pool).wait() }
        try CreateClarity().prepare(on: self.pool).wait()

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
            try clarity.create(on: self.pool).wait()
        }
        do {
            let clarity = try Clarity.query(on: self.pool).first().wait()!
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

    var benchmarker: FluentBenchmarker {
        return .init(database: self.pool)
    }
    var pool: ConnectionPool<MySQLConnectionSource>!

    
    override func setUp() {
        XCTAssert(isLoggingConfigured)
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        let hostname: String
        #if os(Linux)
        hostname = "mysql"
        #else
        hostname = "localhost"
        #endif
        let tlsConfiguration: TLSConfiguration?
        #if TEST_TLS
        tlsConfiguration = .forClient(certificateVerification: .none)
        #else
        tlsConfiguration = nil
        #endif
        let configuration = MySQLConfiguration(
            hostname: hostname,
            port: 3306,
            username: "vapor_username",
            password: "vapor_password",
            database: "vapor_database",
            tlsConfiguration: tlsConfiguration
        )
        let db = MySQLConnectionSource(configuration: configuration, on: eventLoop)
        self.pool = ConnectionPool(config: .init(maxConnections: 1), source: db)
    }
    
    override func tearDown() {
        try! self.pool.close().wait()
        self.pool = nil
    }
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug
        return handler
    }
    return true
}()
