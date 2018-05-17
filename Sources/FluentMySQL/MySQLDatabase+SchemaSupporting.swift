import Async
import Crypto
import Foundation

/// Adds ability to create, update, and delete schemas using a `MySQLDatabase`.
extension MySQLDatabase: SchemaSupporting, IndexSupporting {
    /// See `SchemaSupporting`.
    public typealias SchemaType = MySQLColumnDefinition

    /// See `SchemaSupporting.execute`
    public static func execute(schema: Schema<MySQLDatabase>, on connection: MySQLConnection) -> Future<Void> {
        return Future.flatMap(on: connection) {
            var schemaQuery = try schema.convertToSchemaQuery(dataTypeFactory: dataType)
            try schema.applyReferences(to: &schemaQuery)
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
            return connection.simpleQuery(sqlString).map { rows in
                assert(rows.count == 0)
            }.flatMap {
                /// handle indexes as separate query
                var indexFutures: [Future<Void>] = []
                for addIndex in schema.addIndexes {
                    let fields = try addIndex.fields.map { try "`\($0.convertToDataColumn().name)`" }.joined(separator: ", ")
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

    /// Serializes schema definition field to a `String`.
    private static func dataType(for field: Schema<MySQLDatabase>.FieldDefinition) throws -> String {
        let definition: MySQLColumnDefinition
        switch field.dataType {
        case .custom(let custom): definition = custom
        case .type(let type):
            guard let representable = type as? MySQLColumnDefinitionStaticRepresentable.Type else {
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
            definition = representable.mySQLColumnDefinition
        }
        var string = definition.name
        if let length = definition.length {
            string += "(\(length))"
        }

        string += " " + definition.attributes.joined(separator: " ")

        if field.isIdentifier {
            string += " PRIMARY KEY"
            if definition.name.contains("INT") {
                string += " AUTO_INCREMENT"
            }
        }

        if !field.isOptional {
            string += " NOT NULL"
        }

        return string
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

extension Schema.Index where Database == MySQLDatabase {
    func mysqlIdentifier(for entity: String) throws -> String {
        return try "_fluent_index_\(entity)_" + fields.map { try $0.convertToDataColumn().name }.joined(separator: "_")
    }
}
