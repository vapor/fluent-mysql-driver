import Async
import CodableKit
import Fluent
import Foundation
import MySQL
import Service
import SQL

/// A reference to a MySQL database
public final class MySQLDatabase {
    /// The hostname to which connections will be connected
    let hostname: String
    
    /// The port to which connections will be connected
    let port: UInt16
    
    /// The username to authenticate with
    let user: String
    
    /// The password to authenticate with
    let password: String?
    
    /// The database to select
    let database: String
    
    /// If set, query logs will be sent to the supplied logger.
    public var logger: MySQLLogger?
    
    public init(hostname: String, port: UInt16 = 3306, user: String, password: String?, database: String) {
        self.hostname = hostname
        self.port = port
        self.user = user
        self.password = password
        self.database = database
    }
}

// MARK: Database

extension MySQLDatabase: Database, LogSupporting {
    public typealias Connection = MySQLConnection
    
    public func makeConnection(from config: FluentMySQLConfig, on worker: Worker) -> Future<MySQLConnection> {
        return MySQLConnection.makeConnection(
            hostname: hostname,
            port: port,
            ssl: config.ssl,
            user: user,
            password: password,
            database: database,
            on: worker.eventLoop
        )
    }


    /// See SupportsLogging.enableLogging
    public func enableLogging(using logger: DatabaseLogger) {
        self.logger = logger
    }
}

extension MySQLDatabase: JoinSupporting {}

extension MySQLDatabase: ReferenceSupporting {
    /// ReferenceSupporting.enableReferences
    public static func enableReferences(on connection: MySQLConnection) -> Future<Void> {
        return connection.administrativeQuery("SET FOREIGN_KEY_CHECKS=1;")
    }

    /// ReferenceSupporting.disableReferences
    public static func disableReferences(on connection: MySQLConnection) -> Future<Void> {
        return connection.administrativeQuery("SET FOREIGN_KEY_CHECKS=0;")
    }
}
