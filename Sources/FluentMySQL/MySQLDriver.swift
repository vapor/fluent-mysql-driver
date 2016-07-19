import Fluent
import MySQL

public class MySQLDriver: Fluent.Driver {
    public var idKey: String = "id"
    public var database: MySQL.Database

    /**
        Attempts to establish a connection to a MySQL database
        engine running on host.

        - parameter host: May be either a host name or an IP address.
        If host is the string "localhost", a connection to the local host is assumed.
        - parameter user: The user's MySQL login ID.
        - parameter password: Password for user.
        - parameter database: Database name.
        The connection sets the default database to this value.
        - parameter port: If port is not 0, the value is used as
        the port number for the TCP/IP connection.
        - parameter socket: If socket is not NULL,
        the string specifies the socket or named pipe to use.
        - parameter flag: Usually 0, but can be set to a combination of the
        flags at http://dev.mysql.com/doc/refman/5.7/en/mysql-real-connect.html


        - throws: `Error.connection(String)` if the call to
        `mysql_real_connect()` fails.
    */
    public init(
        host: String,
        user: String,
        password: String,
        database: String,
        port: UInt = 3306,
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

    /**
        Creates the driver from an already
        initialized database.
    */
    public init(_ database: MySQL.Database) {
        self.database = database
    }

    /**
        Queries the database.
    */
    @discardableResult
    public func query<T: Entity>(_ query: Query<T>) throws -> Fluent.Node {
        let serializer = MySQLSerializer(sql: query.sql)
        let (statement, values) = serializer.serialize()

        print(statement)
        // create a reusable connection 
        // so that LAST_INSERT_ID can be fetched
        let connection = try database.makeConnection()

        let results = try mysql(statement, values, connection)

        if query.action == .create {
            let insert = try mysql("SELECT LAST_INSERT_ID() as id", [], connection)
            if
                case .array(let array) = insert,
                let first = array.first,
                case .dictionary(let dict) = first,
                let id = dict["id"]
            {
                return id
            }
        }

        return results
    }

    /**
        Creates the desired schema.
    */
    public func schema(_ schema: Schema) throws {
        let serializer = MySQLSerializer(sql: schema.sql)
        let (statement, values) = serializer.serialize()

        try mysql(statement, values)
    }

    /**
        Conformance to the RawQueryable protocol
        allowing plain query strings and value arrays
        to be attempted.
    */
    @discardableResult
    public func raw(_ query: String, _ values: [Node] = []) throws -> Node {
        return try mysql(query, values)
    }

    /**
        Provides access to the underlying MySQL database
        for running raw queries.
    */
    @discardableResult
    public func mysql(_ query: String, _ values: [Node] = [], _ connection: MySQL.Connection? = nil) throws -> Node {
        var results: [[String: NodeRepresentable]] = []

        let values = values.map { $0.mysql }

        for row in try database.execute(query, values, connection) {
            var result: [String: NodeRepresentable] = [:]

            for (key, val) in row {
                result[key] = val
            }

            results.append(result)
        }

        return Node(results.map({ Node($0) }))
    }
}

extension Node {
    public var mysql: MySQL.Value {
        switch self {
        case .int(let int):
            return .int(int)
        case .string(let string):
            return .string(string)
        case .double(let double):
            return .double(double)
        case .bool(let bool):
            return .int(bool ? 1 : 0)
        case .data(let _):
            return .string("")
        case .null:
            return .null
        default:
            print("Cannot convert Node to MySQL: \(self)")
            return .null
        }
    }
}

extension MySQL.Value: NodeRepresentable {
    public func makeNode() -> Node {
        switch self {
        case .int(let int):
            return .int(int)
        case .string(let string):
            return .string(string)
        default:
            // FIXME
            print("WARNING: \(self)")
            return .string("")
        }
    }
}


