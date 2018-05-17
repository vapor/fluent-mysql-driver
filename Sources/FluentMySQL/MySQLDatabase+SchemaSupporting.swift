import Async
import Crypto
import Foundation

extension MySQLColumnDefinition: SchemaDataType {
    public static func type(_ type: Any.Type) -> MySQLColumnDefinition {
        guard let representable = type as? MySQLColumnDefinitionStaticRepresentable.Type else {
            fatalError("No MySQL column type known for \(type).")
//            throw MySQLError(
//                identifier: "fieldType",
//                reason: "No MySQL column type known for \(type).",
//                suggestedFixes: [
//                    "Conform \(type) to `MySQLColumnDefinitionStaticRepresentable` to specify field type or implement a custom migration.",
//                    "Specify the `MySQLColumnDefinition` manually using the schema builder in a migration."
//                ],
//                source: .capture()
//            )
        }
        return representable.mySQLColumnDefinition
    }
}

public struct MySQLFieldDefinition: SchemaFieldDefinition, DataDefinitionColumnRepresentable {

    public var field: DataColumn
    public var dataType: MySQLColumnDefinition
    public var isOptional: Bool
    public var isIdentifier: Bool

    public static func unit(_ field: DataColumn, _ dataType: MySQLColumnDefinition, isOptional: Bool, isIdentifier: Bool) -> MySQLFieldDefinition {
        return .init(field: field, dataType: dataType, isOptional: isOptional, isIdentifier: isIdentifier)
    }

    public typealias Field = DataColumn
    public typealias DataType = MySQLColumnDefinition


    public func convertToDataDefinitionColumn() -> DataDefinitionColumn {
        var attributes = dataType.attributes
        if isIdentifier {
            attributes.append("PRIMARY KEY")
            if dataType.name.contains("INT") {
                attributes.append("AUTO_INCREMENT")
            }
        }
        if !isOptional {
            attributes.append("NOT NULL")
        }

        var name = dataType.name
        if let length = dataType.length {
            name += "(\(length))"
        }

        return .init(name: field.name, dataType: name, attributes: attributes)
    }
}

/// Adds ability to create, update, and delete schemas using a `MySQLDatabase`.
extension MySQLDatabase: SchemaSupporting, IndexSupporting {
    public typealias FieldDefinition = MySQLFieldDefinition

    /// See `SchemaSupporting.execute`
    public static func execute(schema: Schema<MySQLDatabase>, on connection: MySQLConnection) -> Future<Void> {
        return Future.flatMap(on: connection) {
            var ddl = try schema.convertToDataDefinitionQuery()
            try schema.applyReferences(to: &ddl)
            try ddl.addForeignKeys.mysqlShortenNames()
            try ddl.removeForeignKeys.mysqlShortenNames()

            let sqlString = MySQLSerializer().serialize(query: ddl)
            if let logger = connection.logger {
                logger.log(query: sqlString)
            }
            return connection.simpleQuery(sqlString).map { rows in
                assert(rows.count == 0)
            }.flatMap {
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

extension Schema.Index where Database == MySQLDatabase {
    func mysqlIdentifier(for entity: String) throws -> String {
        return "_fluent_index_\(entity)_" + fields.map { $0.name }.joined(separator: "_")
    }
}
