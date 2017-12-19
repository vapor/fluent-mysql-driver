#if os(Linux)

import XCTest
@testable import FluentMySQLTests

XCTMain([
    testCase(FluentMySQLTests.allTests)
])

#endif
