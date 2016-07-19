import XCTest
@testable import FluentMySQL
import Fluent

class JoinTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic)
    ]

    var database: Fluent.Database!
    var driver: MySQLDriver!

    override func setUp() {
        driver = MySQLDriver.makeTestConnection()
        database = Database(driver: driver)
    }

    final class Atom {
        var id: Value?
        var name: String
        var protons: Int

        init(serialized: Value) {
            id = serialized["id"]
            name = serialized["name"].string ?? ""
            protons = serialized["protons"].int ?? 0
        }
    }

    func testBasic() throws {
        try driver.schema(Schema.delete(entity: "atoms"))
        try driver.schema(Schema.delete(entity: "compounds"))
        try driver.schema(Schema.delete(entity: "atom_compound"))

        try driver.schema(Schema.create(entity: "atoms", create: [
            Schema.Field.id,
            Schema.Field.string("name", length: 16),
            Schema.Field.int("protons")
        ]))

        try driver.schema(Schema.create(entity: "compounds", create: [
            Schema.Field.id,
            Schema.Field.string("name", length: 24)
        ]))

        try driver.schema(Schema.create(entity: "atom_compound", create: [
            Schema.Field.id,
            Schema.Field.int("atom_id"),
            Schema.Field.int("compound_id")
        ]))
    }
}
