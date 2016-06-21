#if os(Linux)

import XCTest
@testable import FluentMySQLTestSuite

XCTMain([
    testCase(MySQLDriverTests.allTests),
])

#endif