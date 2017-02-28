import Fluent
import MySQL

public final class MySQLDriver: Fluent.Driver {
    /// The string value for the
    /// default identifier key.
    ///
    /// The `idKey` will be used when
    /// `Model.find(_:)` or other find
    /// by identifier methods are used.
    ///
    /// This value is overriden by
    /// entities that implement the
    /// `Entity.idKey` static property.
    public let idKey: String

    /// The default type for values stored against the identifier key.
    ///
    /// The `idType` will be accessed by those Entity implementations
    /// which do not themselves implement `Entity.idType`.
    public let idType: IdentifierType

    /// The naming convetion to use for foreign
    /// id keys, table names, etc.
    /// ex: snake_case vs. camelCase.
    public let keyNamingConvention: KeyNamingConvention

    /// The underlying MySQL Database
    public let database: MySQL.Database
    
    /// Attempts to establish a connection to a MySQL database
    /// engine running on host.
    ///
    /// - parameter host: May be either a host name or an IP address.
    ///         If host is the string "localhost", a connection to the local host is assumed.
    /// - parameter user: The user's MySQL login ID.
    /// - parameter password: Password for user.
    /// - parameter database: Database name.
    ///         The connection sets the default database to this value.
    /// - parameter port: If port is not 0, the value is used as
    ///         the port number for the TCP/IP connection.
    /// - parameter socket: If socket is not NULL,
    ///         the string specifies the socket or named pipe to use.
    /// - parameter flag: Usually 0, but can be set to a combination of the
    ///         flags at http://dev.mysql.com/doc/refman/5.7/en/mysql-real-connect.html
    /// - parameter encoding: Usually "utf8", but something like "utf8mb4" may be
    ///         used, since "utf8" does not fully implement the UTF8 standard and does
    ///         not support Unicode.
    ///
    /// - throws: `Error.connection(String)` if the call to
    ///
    public convenience init(
        host: String,
        user: String,
        password: String,
        database: String,
        port: UInt = 3306,
        flag: UInt = 0,
        encoding: String = "utf8",
        idKey: String = "id",
        idType: IdentifierType = .int,
        keyNamingConvention: KeyNamingConvention = .snake_case
    ) throws {
        let database = try MySQL.Database(
            host: host,
            user: user,
            password: password,
            database: database,
            port: port,
            flag: flag,
            encoding: encoding
        )
        self.init(
            database, 
            idKey: idKey, 
            idType: idType, 
            keyNamingConvention: keyNamingConvention
        )
    }
    
    /// Creates the driver from an already
    /// initialized database.
    public init(
        _ database: MySQL.Database,
        idKey: String = "id",
        idType: IdentifierType = .int,
        keyNamingConvention: KeyNamingConvention = .snake_case
    ) {
        self.database = database
        self.idKey = idKey
        self.idType = idType
        self.keyNamingConvention = keyNamingConvention
    }

    /// Creates a connection for executing
    /// queries. This method is used to
    /// automatically create a connection
    /// if any Executor methods are called on
    /// the Driver.
    public func makeConnection() throws -> Fluent.Connection {
        return try database.makeConnection()
    }
}

extension MySQL.Connection: Fluent.Connection {
    public var closed: Bool {
        // TODO: FIXME
        return false
    }

    /// Executes a `Query` from and
    /// returns an array of results fetched,
    /// created, or updated by the action.
    @discardableResult
    public func query<T: Entity>(_ query: Query<T>) throws -> Node {
        let serializer = MySQLSerializer(sql: query.sql)
        let (statement, values) = serializer.serialize()
        let results = try mysql(statement, values)

        if query.action == .create {
            let insert = try mysql("SELECT LAST_INSERT_ID() as id", [])
            if
                case .array(let array) = insert,
                let first = array.first,
                case .object(let obj) = first,
                let id = obj["id"]
            {
                return id
            }
        }

        return results
    }

    /// Creates the `Schema` indicated
    /// by the `Builder`.
    public func schema(_ schema: Schema) throws {
        let serializer = MySQLSerializer(sql: schema.sql)
        let (statement, values) = serializer.serialize()

        try mysql(statement, values)
    }

    /// Drivers that support raw querying
    /// accept string queries and parameterized values.
    ///
    /// This allows Fluent extensions to be written that
    /// can support custom querying behavior.
    @discardableResult
    public func raw(_ raw: String, _ values: [Node]) throws -> Node {
        return try mysql(raw, values)
    }

    @discardableResult
    private func mysql(_ query: String, _ values: [Node] = []) throws -> Node {
        let results = try execute(
            query,
            values as [NodeRepresentable]
        ).map { Node.object($0) }
        return .array(results)
    }
}
