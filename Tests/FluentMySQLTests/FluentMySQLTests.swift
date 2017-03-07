import XCTest
@testable import FluentMySQL
import FluentTester

class FluentMySQLTests: XCTestCase {
    func testAll() throws {
        let driver = MySQLDriver.makeTest()
        let database = Database(driver)
        let tester = Tester(database: database)

        do {
            try tester.testAll()
        } catch {
            XCTFail("\(error)")
        }
    }

    static let allTests = [
        ("testAll", testAll)
    ]
}
