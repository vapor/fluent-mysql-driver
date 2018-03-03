import Async
import SQL
import Fluent
import FluentSQL
import Foundation
import MySQL


extension MySQLDatabase: SchemaSupporting {
    /// Executes the schema query
    public static func execute(
        schema: DatabaseSchema<MySQLDatabase>,
        on connection: MySQLConnection
    ) -> Future<Void> {
        var schemaQuery = schema.makeSchemaQuery(dataTypeFactory: dataType)
        schema.applyReferences(to: &schemaQuery)

        let serializer = MySQLSerializer()
        let sqlString = serializer.serialize(schema: schemaQuery)
        _logger?.log(query: sqlString)

        return connection.administrativeQuery(sqlString)
    }

    /// See SchemaSupporting.dataType
    public static func dataType(for field: SchemaField<MySQLDatabase>) -> String {
        var sql: [String] = []
        sql.append(field.type.name + field.type.lengthName)
        sql.append(field.type.keywords) // appends joined type attributes (e.g: UNSIGNED)

        if field.isIdentifier {
            sql.append("PRIMARY KEY")
            if field.type.name.contains("INT") {
                sql.append("AUTO_INCREMENT")
            }
        }

        if !field.isOptional {
            sql.append("NOT NULL")
        }

        return sql.joined(separator: " ")
    }

    public static func fieldType(for type: Any.Type) throws -> ColumnType {
        if let representable = type as? MySQLColumnRepresentable.Type {
            return representable.mysqlColumn
        } else {
            throw UnknwonMySQLField(type: type)
        }
    }
}

public protocol MySQLColumnRepresentable {
    static var mysqlColumn: ColumnType { get }
}

extension Bool: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .uint8() }
}

extension String: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .varChar(length: 255) }
}

extension Date: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .datetime() }
}

extension Int: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType {
        #if arch(x86_64) || arch(arm64)
            return .int64()
        #else
            return .int32()
        #endif
    }
}

extension UInt: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType {
        #if arch(x86_64) || arch(arm64)
            return .uint64()
        #else
            return .uint32()
        #endif
    }
}

extension Int8: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .int8() }
}

extension Int16: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .int16() }
}

extension Int32: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .int32() }
}

extension Int64: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .int64() }
}

extension UInt8: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .uint8() }
}

extension UInt16: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .uint16() }
}

extension UInt32: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .uint32() }
}

extension UInt64: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .uint64() }
}

extension Double: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .double() }
}

extension Float32: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType { return .float() }
}

extension UUID: MySQLColumnRepresentable {
    public static var mysqlColumn: ColumnType {
        return .varChar(length: 64, binary: true)
    }
}

struct UnknwonMySQLField: Error {
    var type: Any.Type
}
