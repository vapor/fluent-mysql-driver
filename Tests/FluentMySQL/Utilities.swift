import FluentMySQL
import MySQL
import Fluent

import XCTest

extension MySQLDriver {
    static func makeTestConnection() -> MySQLDriver {
        do {
            let mysql = try MySQL.Database(
                host: "127.0.0.1",
                user: "root",
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

final class Atom: Entity {
    var id: Node?
    var name: String
    var protons: Int

    init(_ node: Node) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        protons = try node.extract("protons")
    }

    func makeNode() -> Node {
        return Node([
            "id": id,
            "name": name,
            "protons": protons
        ])
    }

    static func prepare(_ database: Fluent.Database) throws {
        try database.create(entity) { builder in
            builder.id()
            builder.string("name")
            builder.int("protons")
        }
    }
    static func revert(_ database: Fluent.Database) throws {
        try database.delete(entity)
    }
}

final class Compound: Entity {
    var id: Node?
    var name: String

    init(_ node: Node) throws {
        id = try node.extract("id")
        name = try node.extract("name")
    }

    func makeNode() -> Node {
        return Node([
            "id": id,
            "name": name
        ])
    }

    static func prepare(_ database: Fluent.Database) throws {
        try database.create(entity) { builder in
            builder.id()
            builder.string("name")
        }
    }
    static func revert(_ database: Fluent.Database) throws {
        try database.delete(entity)
    }
}

final class User: Entity {
    var id: Fluent.Node?
    var name: String
    var email: String

    init(id: Node?, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }

    func makeNode() -> Node {
        return Node([
            "id": id,
            "name": name,
            "email": email
        ])
    }

    init(_ node: Node) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        email = try node.extract("email")
    }

    static func prepare(_ database: Fluent.Database) throws {
        try database.create(entity) { builder in
            builder.id()
            builder.string("name")
            builder.string("email")
        }
    }
    static func revert(_ database: Fluent.Database) throws {
        try database.delete(entity)
    }
}

