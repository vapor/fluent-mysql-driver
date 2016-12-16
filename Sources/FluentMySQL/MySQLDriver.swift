import Fluent
import MySQL

public class MySQLDriver: Fluent.Driver {
    public var idKey: String = "id"
    public var database: MySQL.Database
    
    /**
        Tells the driver wether or not to make a new database
        connection on every request.
        Keep this off if you want session variables to be retained.
        Setting it to `true` might cause timeout errors if there is no 
        activity during an extended period of time (MySQL default is 8hr).
     */
    public var retainConnection: Bool = false
    
    /**
        The active connection with the database.
    */
    public var connection: Connection?
    
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
        - parameter encoding: Usually "utf8", but something like "utf8mb4" may be
        used, since "utf8" does not fully implement the UTF8 standard and does
        not support Unicode.
        - parameter subSecondResolution: Usually 0 for no fractional seconds and up to 6
        for microsecond resolution


        - throws: `Error.connection(String)` if the call to
        `mysql_real_connect()` fails.
    */
    public init(
        host: String,
        user: String,
        password: String,
        database: String,
        port: UInt = 3306,
        flag: UInt = 0,
        encoding: String = "utf8",
        subSecondResolution: Int = 0 
    ) throws {
        self.database = try MySQL.Database(
            host: host,
            user: user,
            password: password,
            database: database,
            port: port,
            flag: flag,
            encoding: encoding,
            subSecondResolution: subSecondResolution
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
    public func query<T: Entity>(_ query: Query<T>) throws -> Node {
        let serializer = MySQLSerializer(sql: query.sql)
        let (statement, values) = serializer.serialize()
        
        // create a reusable connection
        // so that LAST_INSERT_ID can be fetched
        let connection = try database.makeConnection()
        
        let results = try mysql(statement, values, connection)
        
        if query.action == .create {
            let insert = try mysql("SELECT LAST_INSERT_ID() as id", [], connection)
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
    public func mysql(_ query: String, _ values: [Node] = [], _ conn: MySQL.Connection? = nil) throws -> Node {
        // Create and save a connection if none provided
        var conn = conn ?? connection
        if conn == nil && retainConnection {
            conn = try database.makeConnection()
            connection = conn
        } // If `conn` is still nil, the database will create a temporary connection
        
        let results = try database.execute(query, values.map({ $0 as NodeRepresentable }), conn).map { Node.object($0) }
        return .array(results)
    }
}

