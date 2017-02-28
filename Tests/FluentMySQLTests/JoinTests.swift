import XCTest
@testable import FluentMySQL
import Fluent
import FluentTester

class JoinTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic),
        ("testTester", testTester),
        ("testCreate", testCreate),
    ]

    var database: Fluent.Database!
    var driver: MySQLDriver!

    override func setUp() {
        driver = MySQLDriver.makeTestConnection()
        database = Database(driver)
    }

    func testBasic() throws {
        try Atom.revert(database)
        try Compound.revert(database)
        try Pivot<Atom, Compound>.revert(database)

        Atom.database = database
        Compound.database = database
        Pivot<Atom, Compound>.database = database
            
        try Atom.prepare(database)
        try Compound.prepare(database)
        try Pivot<Atom, Compound>.prepare(database)


        let hydrogen = Atom(name: "Hydrogen", protons: 1)
        try hydrogen.save()
            print(hydrogen.exists)

        let water = Compound(name: "Water")
        try water.save()
        let hydrogenWater = try Pivot<Atom, Compound>(hydrogen, water)
        try hydrogenWater.save()

        let sugar = Compound(name: "Sugar")
        try sugar.save()
        let hydrogenSugar = try Pivot<Atom, Compound>(hydrogen, sugar)
        try hydrogenSugar.save()


        let compounds = try hydrogen.compounds.all()
        XCTAssertEqual(compounds.count, 2)
        XCTAssertEqual(compounds.first?.id?.int, water.id?.int)
        XCTAssertEqual(compounds.last?.id?.int, sugar.id?.int)
        
        try Atom.revert(database)
        try Compound.revert(database)
        try Pivot<Atom, Compound>.revert(database)
    }
    
    func testTester() {
        let tester = Tester(database: database)
        do {
            try Atom.revert(database)
            try Compound.revert(database)
            try Pivot<Atom, Compound>.revert(database)
            try database.delete(custom: "students")
            try tester.testAll()
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testCreate() throws {
        Student.database = database
        
        do {
            try Student.revert(database)
            try Student.prepare(database)
        } catch {
            print(error)
        }
        
        
        let bob = Student(
            name: "Bob",
            age: 22,
            ssn: "382482",
            donor: true,
            meta: Node.object(["hello": Node.string("world")])
        )
        try bob.save()
        
        let fetched = try Student.find(1)
        XCTAssertEqual(fetched?.meta["hello"]?.string, "world")
        XCTAssertEqual(fetched?.age, 22)
    }
}

final class Student: Entity {
    var name: String
    var age: Int
    var ssn: String
    var donor: Bool
    var meta: Node
    let storage = Storage()
    
    init(name: String, age: Int, ssn: String, donor: Bool, meta: Node) {
        self.name = name
        self.age = age
        self.ssn = ssn
        self.donor = donor
        self.meta = meta
    }
    
    init(node: Node, in context: Context) throws {
        name = try node.get("name")
        age = try node.get("age")
        ssn = try node.get("ssn")
        donor = try node.get("donor")
        meta = try node.get("meta")
    }
    
    func makeNode(in context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name,
            "age": age,
            "ssn": ssn,
            "donor": donor,
            "meta": meta
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self) { students in
            students.id(for: self)
            students.string("name", length: 64)
            students.int("age")
            students.string("ssn", unique: true)
            students.bool("donor", default: true)
        }
        
        try database.modify(self) { students in
            students.custom("meta", type: "JSON")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
