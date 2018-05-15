import Async
import Crypto
import Foundation

/// Adds ability to create, update, and delete schemas using a `MySQLDatabase`.
extension MySQLDatabase: SchemaSupporting, IndexSupporting {
    /// See `SchemaSupporting.dataType`
    public static func dataType(for field: SchemaField<MySQLDatabase>) -> String {
        var string = field.type.name

        if let length = field.type.length {
            string += "(\(length))"
        }

        string += " " + field.type.attributes.joined(separator: " ")

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
            try schemaQuery.addForeignKeys.mysqlShortenNames()
            try schemaQuery.removeForeignKeys.mysqlShortenNames()


            /// Apply custom sql transformations
            var sqlQuery: SQLQuery = .definition(schemaQuery)
            for customSQL in schema.customSQL {
                customSQL.closure(&sqlQuery)
            }

            let sqlString = MySQLSerializer().serialize(sqlQuery)
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
                    let name = try addIndex.mysqlIdentifier(for: schema.entity).mysqlShortenedName()
                    let add = connection.simpleQuery("CREATE \(addIndex.isUnique ? "UNIQUE " : "")INDEX `\(name)` ON `\(schema.entity)` (\(fields))").map(to: Void.self) { rows in
                        assert(rows.count == 0)
                    }
                    indexFutures.append(add)
                }
                for removeIndex in schema.removeIndexes {
                    let name = try removeIndex.mysqlIdentifier(for: schema.entity).mysqlShortenedName()
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

// MARK: Utilities

extension String {
    func mysqlShortenedName() throws -> String {
        return try "_fluent_" + MD5.hash(self).base64URLEncodedString()
    }
}

extension String {
    mutating func mysqlShortenName() throws {
        self = try mysqlShortenedName()
    }
}

extension DataDefinitionForeignKey {
    mutating func mysqlShortenName() throws {
        try name.mysqlShortenName()
    }
}

extension Array where Element == DataDefinitionForeignKey {
    mutating func mysqlShortenNames() throws {
        for i in 0..<count {
            try self[i].mysqlShortenName()
        }
    }
}

extension Array where Element == String {
    mutating func mysqlShortenNames() throws {
        for i in 0..<count {
            try self[i].mysqlShortenName()
        }
    }
}

extension SchemaIndex where Database == MySQLDatabase {
    func mysqlIdentifier(for entity: String) -> String {
        return "_fluent_index_\(entity)_" + fields.map { $0.name }.joined(separator: "_")
    }
}
