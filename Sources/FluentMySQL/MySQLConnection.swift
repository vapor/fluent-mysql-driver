import Async
import CodableKit
import Fluent
import FluentSQL
import MySQL
import SQL

/// A MySQL query serializer
internal final class MySQLSerializer: SQLSerializer {
    internal init () {}
}

extension MySQLConnection: DatabaseConnection {
    public typealias Config = FluentMySQLConfig

    public func existingConnection<D>(to type: D.Type) -> D.Connection? where D: Database {
        return self as? D.Connection
    }

    public func connect<D>(to database: DatabaseIdentifier<D>) -> Future<D.Connection> {
        fatalError("Cannot call `.connect(to:)` on an existing connection. Call `.existingConnection` instead.")
    }
}
//
///// An error that gets thrown if the ConnectionRepresentable needs to represent itself but fails to do so because it is used in a different context
//struct InvalidConnectionType: Error{}
//
///// A Fluent wrapper around a MySQL connection that can log
//public final class FluentMySQLConnection: DatabaseConnectable {
//    public typealias Config = FluentMySQLConfig
//
//    public func close() {
//        self.connection.close()
//    }
//
//    public func existingConnection<D>(to type: D.Type) -> D.Connection? where D : Database {
//        return self as? D.Connection
//    }
//
//    /// Respresents the current FluentMySQLConnection as a connection to `D`
//    public func connect<D>(to database: DatabaseIdentifier<D>) -> Future<D.Connection> {
//        fatalError("Call `.existingConnection` first.")
//    }
//
//    /// Keeps track of logs by MySQL
//    let logger: MySQLLogger?
//
//    /// The underlying MySQL Connection that can be used for normal queries
//    public let connection: MySQLConnection
//
//    /// Used to create a new FluentMySQLConnection wrapper
//    init(connection: MySQLConnection, logger: MySQLLogger?) {
//        self.connection = connection
//        self.logger = logger
//    }
//
//    /// See QueryExecutor.execute
//    internal func execute<I, D>(
//        query: DatabaseQuery<MySQLDatabase>,
//        into stream: I
//    ) where I : Async.InputStream, D == I.Input, D: Decodable {
//
//    }
//
//}
//
