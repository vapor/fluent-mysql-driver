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
    public var connection: MySQL.Connection?
    
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
        encoding: String = "utf8"
    ) throws {
        self.database = try MySQL.Database(
            host: host,
            user: user,
            password: password,
            database: database,
            port: port,
            flag: flag,
            encoding: encoding
        )
    }
    
    /**
        Creates the driver from an already
        initialized database.
    */
    public init(_ database: MySQL.Database) {
        self.database = database
    }
    
    public func makeConnection() throws -> Fluent.Connection {
        return MySQLConnection(connection: try database.makeConnection())
    }
}
