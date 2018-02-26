import Async
import CodableKit
import Fluent
import Foundation
import MySQL
import Service
import SQL

/// A reference to a MySQL database
public final class MySQLDatabase: Service {
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
    
    /// Initialize MySQLDatabase with a DB URL
    public convenience init?(databaseURL: String) {
        guard let url = URL(string: databaseURL),
            url.scheme == "mysql",
            url.pathComponents.count == 2,
            let hostname = url.host,
            let username = url.user
            else {return nil}

        let password = url.password
        let database = url.pathComponents[1]
        self.init(hostname: hostname, user: username, password: password, database: database)
    }
}

// MARK: Database

extension MySQLDatabase: Database, LogSupporting {
    public typealias Connection = MySQLConnection
    
    public func makeConnection(using config: MySQLConnectionConfig, on worker: Worker) -> Future<MySQLConnection> {
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

// MARK: Model

/// A MySQL database model.
/// See `Fluent.Model`.
public protocol MySQLModel: Model where Self.Database == MySQLDatabase, Self.ID == Int {
  /// This MySQL Model's unique identifier.
  var id: ID? { get set }
}

extension MySQLModel {
  /// See `Model.ID`
  public typealias ID = Int

  /// See `Model.idKey`
  public static var idKey: IDKey { return \.id }
}

/// A MySQL database pivot.
/// See `Fluent.Pivot`.
public protocol MySQLPivot: Pivot, MySQLModel { }

/// A MySQL database UUID model.
/// See `Fluent.Model`.
public protocol MySQLUUIDModel: Model where Self.Database == MySQLDatabase, Self.ID == UUID {
  /// This MySQL Model's unique identifier.
  var id: UUID? { get set }
}

extension MySQLUUIDModel {
  /// See `Model.ID`
  public typealias ID = UUID

  /// See `Model.idKey`
  public static var idKey: IDKey { return \.id }
}

/// A MySQL database UUID pivot.
/// See `Fluent.Pivot`.
public protocol MySQLUUIDPivot: Pivot, MySQLUUIDModel { }

extension DatabaseIdentifier {
    /// The main MySQL database identifier.
    public static var mysql: DatabaseIdentifier<MySQLDatabase> {
        return .init("mysql")
    }
}

