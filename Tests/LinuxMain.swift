#if os(Linux)

import XCTest
@testable import MySQLDriverTests

XCTMain([
    testCase(FluentMySQLTests.allTests)
])

#endif
