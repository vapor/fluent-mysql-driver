import Fluent

final class Atom: Entity {
    var id: Node?
    var name: String
    var protons: Int
    let storage = Storage()

    init(name: String, protons: Int) {
        self.name = name
        self.protons = protons
    }

    init(node: Node, in context: Context) throws {
        id = try node.get("id")
        name = try node.get("name")
        protons = try node.get("protons")
    }

    func makeNode(in context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name,
            "protons": protons
        ])
    }

    var compounds: Siblings<Atom, Compound, Pivot<Atom, Compound>> {
        return siblings()
    }

    static func prepare(_ database: Fluent.Database) throws {
        try database.create(self) { builder in
            builder.id(for: self)
            builder.string("name")
            builder.int("protons")
        }
    }
    static func revert(_ database: Fluent.Database) throws {
        try database.delete(self)
    }
}
