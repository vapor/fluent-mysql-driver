import Fluent
import MySQL

public class MySQLDriver: Fluent.Driver {
    public var idKey: String = "id"
    public var database: MySQL.Database

    public init(
        host: String,
        user: String,
        password: String,
        database: String,
        port: UInt32 = 3306,
        flag: UInt = 0
    ) throws {
        self.database = try MySQL.Database(
            host: host,
            user: user,
            password: password,
            database: database,
            port: port,
            flag: flag
        )
    }

    public init(_ database: MySQL.Database) {
        self.database = database
    }

    @discardableResult
    public func query<T: Model>(_ query: Query<T>) throws -> [[String: Fluent.Value]] {
        let serializer = MySQLSerializer(sql: query.sql)
        let (statement, values) = serializer.serialize()

        var results = try raw(statement, values)

        if query.action == .create {
            if let insert = try raw("SELECT LAST_INSERT_ID() as id").first?["id"] {
                results.append([
                    "id": insert
                ])
            }
        }

        return results
    }

    public func build(_ builder: Schema.Builder) throws {

    }

    @discardableResult
    public func raw(_ query: String, _ values: [Fluent.Value] = []) throws -> [[String: Fluent.Value]] {
        print(query)
        print(values)
        var results: [[String: Fluent.Value]] = []

        let values = values.map { $0.mysql }

        for row in try database.execute(query, values) {
            var result: [String: Fluent.Value] = [:]

            for (key, val) in row {
                result[key] = val
            }

            results.append(result)
        }

        return results
    }
}

extension Fluent.Value {
    public var mysql: MySQL.Value {
        switch structuredData {
        case .int(let int):
            return .int(int)
        case .double(let double):
            return .double(double)
        case .string(let string):
            return .string(string)
        default:
            return .null
        }
    }
}

extension MySQL.Value: Fluent.Value {
    public var structuredData: StructuredData {
        switch self {
        case .string(let string):
            return .string(string)
        case .int(let int):
            return .int(int)
        case .uint(let uint):
            return .int(Int(uint))
        case .double(let double):
            return .double(double)
        case .null:
            return .null
        }
    }

    public var description: String {
        switch self {
        case .string(let string):
            return string
        case int(let int):
            return "\(int)"
        case .uint(let uint):
            return "\(uint)"
        case .double(let double):
            return "\(double)"
        case .null:
            return "NULL"
        }
    }
}


