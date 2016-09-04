#if os(Linux)

import XCTest
@testable import FluentMySQLTests

XCTMain([
    testCase(MySQLDriverTests.allTests),
])

#endif
