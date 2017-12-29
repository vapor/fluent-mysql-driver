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

        var schemaQuery = schema.makeSchemaQuery()

        switch schemaQuery.statement {
        case .create(let cols, _):
            schemaQuery.statement = .create(
                columns: cols,
                foreignKeys: schema.makeForeignKeys()
            )
        default: break
        }

        // _ = connection.log(query: query)

        let serializer = MySQLSerializer()
        let sqlString = serializer.serialize(schema: schemaQuery)

        return connection.administrativeQuery(sqlString)
    }

    /// See SchemaSupporting.dataType
    public static func dataType(for field: SchemaField<MySQLDatabase>) -> String {
        var sql: [String] = []
        sql.append(field.type.name + field.type.lengthName)


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
        default: fatalError()
        }
    }
}

func id(_ type: Any.Type) -> ObjectIdentifier {
    return ObjectIdentifier(type)
}
