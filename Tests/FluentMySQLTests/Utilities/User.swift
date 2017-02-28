import Fluent

final class User: Entity {
    var name: String
    var email: String
    let storage = Storage()

    init(id: Node?, name: String, email: String) {
        self.name = name
        self.email = email
        self.id = id
    }

    func makeNode(in context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name,
            "email": email
        ])
    }

    init(node: Node, in context: Context) throws {
        name = try node.get("name")
        email = try node.get("email")
    }

    static func prepare(_ database: Fluent.Database) throws {
        try database.create(self) { builder in
            builder.id(for: self)
            builder.string("name")
            builder.string("email")
        }
    }
    static func revert(_ database: Fluent.Database) throws {
        try database.delete(self)
    }
}
