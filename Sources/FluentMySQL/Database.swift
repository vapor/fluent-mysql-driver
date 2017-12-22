import Async
import Fluent
import Foundation
import MySQL
import Service

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
    public var logger: DatabaseLogger?

    /// Creates a new MySQL database.
    public init(hostname: String, port: UInt16 = 3306, user: String, password: String?, database: String) {
        self.hostname = hostname
        self.port = port
        self.user = user
        self.password = password
        self.database = database
    }
}

extension MySQLDatabase: QuerySupporting {
    /// See QuerySupporting.idType
    public static func idType<T>(for type: T.Type) -> IDType where T: Fluent.ID {
        if T.self is MySQLLastInsertIDConvertible.Type {
            return .driver
        } else if T.self is FluentGeneratableID.Type {
            return .fluent
        } else {
            return .user
        }
    }
}

extension MySQLDatabase: TransactionSupporting { }

extension MySQLDatabase: SchemaSupporting {
    /// See SchemaSupporting.FieldType
    public typealias FieldType = ColumnType

    /// See SchemaSupporting.dataType
    public static func dataType(for field: SchemaField<MySQLDatabase>) -> String {
        var sql: [String] = []
        sql.append(field.type.name + field.type.lengthName)
        if !field.isOptional {
            sql.append("NOT NULL")
        }
        if field.isIdentifier {
            if field.type.name.contains("INT") {
                sql.append("AUTO_INCREMENT")
            }
            sql.append("PRIMARY KEY")
        }
        return sql.joined(separator: " ")
    }

    /// See SchemaSupporting.fieldType
    public static func fieldType(for type: Any.Type) throws -> ColumnType {
        switch id(type) {
        case id(Int.self):
            #if arch(x86_64) || arch(arm64)
                return .int64()
            #else
                return .int32()
            #endif
        case id(Int8.self): return .int8()
        case id(Int16.self): return .int16()
        case id(Int32.self): return .int32()
        case id(Int64.self): return .int64()
        case id(UInt.self):
            #if arch(x86_64) || arch(arm64)
                return .uint64()
            #else
                return .uint32()
            #endif
        case id(UInt8.self): return .uint8()
        case id(UInt16.self): return .uint16()
        case id(UInt32.self): return .uint32()
        case id(UInt64.self): return .uint64()
        case id(String.self): return .varChar(length: 255)
        case id(Bool.self): return .uint8()
        case id(Date.self): return .datetime()
        case id(Double.self): return .double()
        case id(Float32.self): return .float()
        case id(UUID.self): return .varChar(length: 64, binary: true)
        default: fatalError("Unsupported type")
        }
    }
}

extension MySQLDatabase: LogSupporting {
    /// See SupportsLogging.enableLogging
    public func enableLogging(using logger: DatabaseLogger) {
        self.logger = logger
    }
}

extension MySQLDatabase: JoinSupporting { }
extension MySQLDatabase: ReferenceSupporting {}

extension MySQLDatabase: Database {
    public func makeConnection(from config: FluentMySQLConfig, on worker: Worker) -> Future<FluentMySQLConnection> {
        return MySQLConnection.makeConnection(
            hostname: hostname,
            port: port,
            ssl: config.ssl,
            user: user,
            password: password,
            database: database,
            on: worker.eventLoop
        ).map(to: FluentMySQLConnection.self) { connection in
            return FluentMySQLConnection(connection: connection, logger: self.logger)
        }
    }
    
    public typealias Connection = FluentMySQLConnection
}

/// Last ID convertible types
protocol MySQLLastInsertIDConvertible {
    static func convert(from int: UInt64) -> Self
}

extension MySQLLastInsertIDConvertible where Self: BinaryInteger {
    static func convert(from int: UInt64) -> Self {
        return numericCast(int)
    }
}

extension Int: MySQLLastInsertIDConvertible { }
extension Int8: MySQLLastInsertIDConvertible { }
extension Int16: MySQLLastInsertIDConvertible { }
extension Int32: MySQLLastInsertIDConvertible { }
extension Int64: MySQLLastInsertIDConvertible { }
extension UInt: MySQLLastInsertIDConvertible { }
extension UInt8: MySQLLastInsertIDConvertible { }
extension UInt16: MySQLLastInsertIDConvertible { }
extension UInt32: MySQLLastInsertIDConvertible { }
extension UInt64: MySQLLastInsertIDConvertible { }

func id(_ type: Any.Type) -> ObjectIdentifier {
    return ObjectIdentifier(type)
}
