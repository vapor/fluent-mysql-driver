import Crypto

extension MySQLDatabase: SQLConstraintIdentifierNormalizer {
    public static func normalizeSQLConstraintIdentifier(_ identifier: String) -> String {
        do {
            return try SHA1.hash(identifier).hexEncodedString()
        } catch {
            print("[ERROR] [MySQL] Could not hash MySQL constraint identifier: \(error).")
            return identifier
        }
    }
}

extension MySQLDatabase: SchemaSupporting {
    /// See `SchemaSupporting`.
    public typealias Schema = FluentMySQLSchema
    
    /// See `SchemaSupporting`.
    public typealias SchemaAction = FluentMySQLSchemaStatement
    
    /// See `SchemaSupporting`.
    public typealias SchemaField = MySQLColumnDefinition
    
    /// See `SchemaSupporting`.
    public typealias SchemaFieldType = MySQLDataType
    
    /// See `SchemaSupporting`.
    public typealias SchemaConstraint = MySQLTableConstraint
    
    /// See `SchemaSupporting`.
    public typealias SchemaReferenceAction = MySQLForeignKeyAction
    
    /// See `SchemaSupporting`.
    public static func schemaField(for type: Any.Type, isIdentifier: Bool, _ field: MySQLColumnIdentifier) -> MySQLColumnDefinition {
        var type = type
        var constraints: [MySQLColumnConstraint] = []
        
        if let optional = type as? AnyOptionalType.Type {
            type = optional.anyWrappedType
        } else {
            constraints.append(.notNull)
        }
        
        let typeName: MySQLDataType
        if let mysql = type as? MySQLDataTypeStaticRepresentable.Type {
            typeName = mysql.mysqlDataType
        } else {
            typeName = .json
        }
        
        if isIdentifier {
            constraints.append(.notNull)
            switch typeName {
            case .tinyint, .smallint, .int, .bigint:
                constraints.append(.primaryKey(default: .autoIncrement))
            default:
                constraints.append(.primaryKey(default: nil))
            }
        }
        
        return .columnDefinition(field, typeName, constraints)
    }
    
    /// See `SchemaSupporting`.
    public static func schemaExecute(_ fluent: FluentMySQLSchema, on conn: MySQLConnection) -> Future<Void> {
        let query: MySQLQuery
        switch fluent.statement {
        case ._createTable:
            var createTable: MySQLCreateTable = .createTable(fluent.table)
            createTable.columns = fluent.columns
            createTable.tableConstraints = fluent.constraints
            query = ._createTable(createTable)
        case ._alterTable:
            var alterTable: MySQLAlterTable = .alterTable(fluent.table)
            alterTable.columns = fluent.columns
            alterTable.deleteColumns = fluent.deleteColumns
            alterTable.constraints = fluent.constraints
            alterTable.columnPositions = fluent.columnPositions
            query = ._alterTable(alterTable)
        case ._dropTable:
            let dropTable: MySQLDropTable = .dropTable(fluent.table)
            query = ._dropTable(dropTable)
        }
        return conn.query(query).transform(to: ())
    }
    
    /// See `SchemaSupporting`.
    public static func enableReferences(on conn: MySQLConnection) -> Future<Void> {
        return conn.raw("SET @@session.foreign_key_checks=1").run()
    }
    
    /// See `SchemaSupporting`.
    public static func disableReferences(on conn: MySQLConnection) -> Future<Void> {
        return conn.raw("SET @@session.foreign_key_checks=0").run()
    }
}
