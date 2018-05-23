import Async
import Crypto
import Foundation

public struct MySQLSchema: SQLSchema {
    public static func fluentSchema(_ entity: String) -> MySQLSchema {
        return .init(table: entity)
    }
    
    public static var fluentCreateIndexesKey: WritableKeyPath<MySQLSchema, [MySQLIndex]> {
        return \.createIndexes
    }

    public static var fluentDeleteIndexesKey: WritableKeyPath<MySQLSchema, [MySQLIndex]> {
        return \.deleteIndexes
    }

    public typealias Action = DataDefinitionStatement
    public typealias Field = DataColumn
    public typealias FieldDefinition = MySQLFieldDefinition
    public typealias Reference = DataDefinitionForeignKey
    public typealias Index = MySQLIndex

    public var table: String
    public var statement: DataDefinitionStatement
    public var createColumns: [MySQLFieldDefinition]
    public var deleteColumns: [DataColumn]
    public var createForeignKeys: [DataDefinitionForeignKey]
    public var deleteForeignKeys: [DataDefinitionForeignKey]
    public var createIndexes: [MySQLIndex]
    public var deleteIndexes: [MySQLIndex]

    public init(table: String) {
        self.table = table
        self.statement = .create
        self.createColumns = []
        self.deleteColumns = []
        self.createForeignKeys = []
        self.deleteForeignKeys = []
        self.createIndexes = []
        self.deleteIndexes = []
    }
}

public struct MySQLIndex: SchemaIndex {
    public typealias Field = DataColumn

    public static func fluentIndex(fields: [DataColumn], isUnique: Bool) -> MySQLIndex {
        return .init(fields: fields, isUnique: isUnique)
    }

    public var fields: [DataColumn]
    public var isUnique: Bool

    internal func mysqlIdentifier(for entity: String) -> String {
        return "_fluent_index_\(entity)_" + fields.map { $0.name }.joined(separator: "_")
    }

    public init(fields: [DataColumn] = [], isUnique: Bool = false) {
        self.fields = fields
        self.isUnique = isUnique
    }
}

extension MySQLColumnDefinition: SchemaDataType {
    public static func fluentType(_ type: Any.Type) -> MySQLColumnDefinition {
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
    public var isIdentifier: Bool

    public static func fluentFieldDefinition(_ field: DataColumn, _ dataType: MySQLColumnDefinition, isIdentifier: Bool) -> MySQLFieldDefinition {
        return .init(field: field, dataType: dataType, isIdentifier: isIdentifier)
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
        var name = dataType.name
        if let length = dataType.length {
            name += "(\(length))"
        }
        return .init(name: field.name, dataType: name, attributes: attributes)
    }
}

/// Adds ability to create, update, and delete schemas using a `MySQLDatabase`.
extension MySQLDatabase: SchemaSupporting {
    /// See `ReferenceSupporting.enableReferences(on:)`
    public static func enableReferences(on connection: MySQLConnection) -> Future<Void> {
        return connection.simpleQuery("SET foreign_key_checks = 1;").transform(to: ())
    }

    /// See `ReferenceSupporting.disableReferences(on:)`
    public static func disableReferences(on connection: MySQLConnection) -> Future<Void> {
        return connection.simpleQuery("SET foreign_key_checks = 0;").transform(to: ())
    }

    /// See `SchemaSupporting.execute`
    public static func execute(schema: MySQLSchema, on conn: MySQLConnection) -> Future<Void> {
        do {
            var ddl = try schema.convertToDataDefinitionQuery()
            try ddl.addForeignKeys.mysqlShortenNames()
            try ddl.removeForeignKeys.mysqlShortenNames()

            let sqlString = MySQLSerializer().serialize(query: ddl)
            if let logger = conn.logger {
                logger.log(query: sqlString)
            }
            return conn.simpleQuery(sqlString).transform(to: ()).flatMap {
                let indexCount = schema.createIndexes.count + schema.deleteIndexes.count
                guard indexCount > 0 else {
                    return conn.eventLoop.newSucceededFuture(result: ())
                }
                /// handle indexes as separate query
                var indexes: [Future<Void>] = []
                indexes.reserveCapacity(indexCount)
                indexes += try schema.createIndexes.map { index in
                    let fields = index.fields.map { "`\($0.name)`" }.joined(separator: ", ")
                    let name = try index.mysqlIdentifier(for: schema.table).mysqlShortenedName()
                    let prefix: String
                    if index.isUnique {
                        prefix = "CREATE UNIQUE INDEX"
                    } else {
                        prefix = "CREATE INDEX"
                    }
                    return conn.simpleQuery("\(prefix) `\(name)` ON `\(schema.table)` (\(fields))").transform(to: ())
                }
                indexes += try schema.deleteIndexes.map { index in
                    let name = try index.mysqlIdentifier(for: schema.table).mysqlShortenedName()
                    return conn.simpleQuery("DROP INDEX `\(name)`").transform(to: ())
                }
                return indexes.flatten(on: conn)
            }
        } catch {
            return conn.eventLoop.newFailedFuture(error: error)
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
