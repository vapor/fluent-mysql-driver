#if os(Linux)

import XCTest
@testable import FluentMySQLTests

XCTMain([
    testCase(MySQLDriverTests.allTests),
    testCase(MySQLDriverTests.allTests),
    testCase(SchemaTests.allTests),
    testCase(CreatorMySQLTests.allTests)
])

#endif
