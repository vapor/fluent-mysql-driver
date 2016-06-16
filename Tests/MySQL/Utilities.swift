import XCTest

import MySQL
import FluentMySQL
import Fluent

extension MySQLDriver {
    static func makeTestConnection() -> MySQLDriver {
        do {
            let mysql = try MySQL.Database(
                host: "127.0.0.1",
                user: "travis",
                password: "",
                database: "test"
            )
            return MySQLDriver(mysql)
        } catch {
            print()
            print()
            print("⚠️ MySQL Not Configured ⚠️")
            print()
            print("Error: \(error)")
            print()
            print("You must configure MySQL to run with the following configuration: ")
            print("    user: 'travis'")
            print("    password: '' // (empty)")
            print("    host: '127.0.0.1'")
            print("    database: 'test'")
            print()

            print()

            XCTFail("Configure MySQL")
            fatalError("Configure MySQL")
        }
    }
}
