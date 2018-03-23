import Async
import Foundation

/// Adds ability to create, update, and delete schemas using a `MySQLDatabase`.
extension MySQLDatabase: SchemaSupporting, IndexSupporting {
    /// See `SchemaSupporting.dataType`
    public static func dataType(for field: SchemaField<MySQLDatabase>) -> String {
        var string = field.type.name

        if let length = field.type.length {
            string += "(\(length))"
        }

        string += field.type.attributes.joined(separator: " ")

        if field.isIdentifier {
            string += " PRIMARY KEY"
            if field.type.name.contains("INT") {
                string += " AUTO_INCREMENT"
            }
        }

        if !field.isOptional {
            string += " NOT NULL"
        }

        return string
    }

    /// See `SchemaSupporting.fieldType`
    public static func fieldType(for type: Any.Type) throws -> MySQLColumnDefinition {
        if let representable = type as? MySQLColumnDefinitionStaticRepresentable.Type {
            return representable.mySQLColumnDefinition
        } else {
            throw MySQLError(
                identifier: "fieldType",
                reason: "No MySQL column type known for \(type).",
                suggestedFixes: [
                    "Conform \(type) to `MySQLColumnDefinitionStaticRepresentable` to specify field type or implement a custom migration.",
                    "Specify the `MySQLColumnDefinition` manually using the schema builder in a migration."
                ],
                source: .capture()
            )
        }
    }

    /// See `SchemaSupporting.execute`
    public static func execute(schema: DatabaseSchema<MySQLDatabase>, on connection: MySQLConnection) -> Future<Void> {
        return Future.flatMap(on: connection) {
            var schemaQuery = schema.makeSchemaQuery(dataTypeFactory: dataType)
            schema.applyReferences(to: &schemaQuery)
            let sqlString = MySQLSerializer().serialize(schema: schemaQuery)
            if let logger = connection.logger {
                logger.log(query: sqlString)
            }
            return connection.simpleQuery(sqlString).map(to: Void.self) { rows in
                assert(rows.count == 0)
            }.flatMap(to: Void.self) {
                /// handle indexes as separate query
                var indexFutures: [Future<Void>] = []
                for addIndex in schema.addIndexes {
                    let fields = addIndex.fields.map { "`\($0.name)`" }.joined(separator: ", ")
                    let name = addIndex.psqlName(for: schema.entity)
                    let add = connection.simpleQuery("CREATE \(addIndex.isUnique ? "UNIQUE " : "")INDEX `\(name)` ON `\(schema.entity)` (\(fields))").map(to: Void.self) { rows in
                        assert(rows.count == 0)
                    }
                    indexFutures.append(add)
                }
                for removeIndex in schema.removeIndexes {
                    let name = removeIndex.psqlName(for: schema.entity)
                    let remove = connection.simpleQuery("DROP INDEX `\(name)`").map(to: Void.self) { rows in
                        assert(rows.count == 0)
                    }
                    indexFutures.append(remove)
                }
                return indexFutures.flatten(on: connection)
            }
        }
    }
}

extension SchemaIndex {
    func psqlName(for entity: String) -> String {
        return "_fluent_index_\(entity)_" + fields.map { $0.name }.joined(separator: "_")
    }
}
