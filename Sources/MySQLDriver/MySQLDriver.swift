import Fluent
import MySQL
import Random

public final class Driver: Fluent.Driver {
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

    /// The master MySQL Database for read/write
    public let master: MySQL.Database
    
    /// The read replicas for read only
    public let readReplicas: [MySQL.Database]
    
    /// Stores query logger
    public var queryLogger: QueryLogger?
    
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
        masterHostname: String,
        readReplicaHostnames: [String],
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
        let master = try MySQL.Database(
            hostname: masterHostname,
            user: user,
            password: password,
            database: database,
            port: port,
            flag: flag,
            encoding: encoding
        )
        let readReplicas: [MySQL.Database] = try readReplicaHostnames.map { hostname in
            return try MySQL.Database(
                hostname: hostname,
                user: user,
                password: password,
                database: database,
                port: port,
                flag: flag,
                encoding: encoding
            )
        }
        self.init(
            master: master,
            readReplicas: readReplicas,
            idKey: idKey, 
            idType: idType, 
            keyNamingConvention: keyNamingConvention
        )
    }
    
    /// Creates the driver from an already
    /// initialized database.
    public init(
        master: MySQL.Database,
        readReplicas: [MySQL.Database] = [],
        idKey: String = "id",
        idType: IdentifierType = .int,
        keyNamingConvention: KeyNamingConvention = .snake_case
    ) {
        self.master = master
        self.readReplicas = readReplicas
        self.idKey = idKey
        self.idType = idType
        self.keyNamingConvention = keyNamingConvention
    }

    /// Creates a connection for executing
    /// queries. This method is used to
    /// automatically create a connection
    /// if any Executor methods are called on
    /// the Driver.
    public func makeConnection(_ type: ConnectionType) throws -> Fluent.Connection {
        let database: MySQL.Database
        switch type {
        case .read:
            database = readReplicas.random ?? master
        case .readWrite:
            database = master
        }
        let conn = try Connection(database.makeConnection())
        conn.queryLogger = queryLogger
        return conn
    }
}

extension Driver: Transactable {
    /// Executes a MySQL transaction on a single connection.
    ///
    /// The argument supplied to the closure is the connection
    /// to use for this transaction.
    ///
    /// It may be ignored if you are using Fluent and not performing
    /// complex threading.
    public func transaction<R>(_ closure: (Fluent.Connection) throws -> R) throws -> R {
        let conn = try master.makeConnection()
        return try conn.transaction {
            let wrapped = MySQLDriver.Connection(conn)
            wrapped.queryLogger = self.queryLogger
            return try closure(wrapped)
        }
    }
}
