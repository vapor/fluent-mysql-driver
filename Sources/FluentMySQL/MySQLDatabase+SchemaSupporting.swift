import Crypto

extension MySQLQuery {
    public struct FluentSchema {
        public enum Statement {
            case create
            case alter
            case drop
        }
        
        public var statement: Statement
        public var table: TableName
        public var columns: [MySQLQuery.ColumnDefinition]
        public var constraints: [MySQLQuery.TableConstraint]
        public init(_ statement: Statement, table: TableName) {
            self.statement = statement
            self.table = table
            self.columns = []
            self.constraints = []
        }
    }
}

extension MySQLDatabase: SchemaSupporting {
    /// See `SchemaSupporting`.
    public typealias Schema = MySQLQuery.FluentSchema
    
    /// See `SchemaSupporting`.
    public typealias SchemaAction = MySQLQuery.FluentSchema.Statement
    
    /// See `SchemaSupporting`.
    public typealias SchemaField = MySQLQuery.ColumnDefinition
    
    /// See `SchemaSupporting`.
    public typealias SchemaFieldType = MySQLQuery.TypeName
    
    /// See `SchemaSupporting`.
    public typealias SchemaConstraint = MySQLQuery.TableConstraint
    
    /// See `SchemaSupporting`.
    public typealias SchemaReferenceAction = MySQLQuery.ForeignKeyReference.Action
    
    /// See `SchemaSupporting`.
    public static var schemaActionCreate: MySQLQuery.FluentSchema.Statement {
        return .create
    }
    
    /// See `SchemaSupporting`.
    public static var schemaActionUpdate: MySQLQuery.FluentSchema.Statement {
        return .alter
    }
    
    /// See `SchemaSupporting`.
    public static var schemaActionDelete: MySQLQuery.FluentSchema.Statement {
        return .drop
    }
    
    /// See `SchemaSupporting`.
    public static func schemaCreate(_ action: MySQLQuery.FluentSchema.Statement, _ entity: String) -> MySQLQuery.FluentSchema {
        return .init(action, table: .init(name: entity))
    }
    
    /// See `SchemaSupporting`.
    public static func schemaField(for type: Any.Type, isIdentifier: Bool, _ field: MySQLQuery.QualifiedColumnName) -> MySQLQuery.ColumnDefinition {
        var type = type
        var constraints: [MySQLQuery.ColumnConstraint] = []
        
        if let optional = type as? AnyOptionalType.Type {
            type = optional.anyWrappedType
        } else {
            constraints.append(.notNull)
        }
        
        let typeName: MySQLQuery.TypeName
        if let mysql = type as? MySQLColumnDefinitionStaticRepresentable.Type {
            typeName = mysql.mySQLColumnDefinition
        } else {
            typeName = .json
        }
        
        if isIdentifier {
            constraints.append(.notNull)
            switch typeName {
            case .tinyint, .smallint, .int, .bigint: constraints.append(.primaryKey(autoIncrement: true))
            default: constraints.append(.primaryKey(autoIncrement: false))
            }
        }
        
        return .init(name: field.name, typeName: typeName, constraints: constraints)
    }
    
    /// See `SchemaSupporting`.
    public static func schemaField(_ field: MySQLQuery.QualifiedColumnName, _ type: MySQLQuery.TypeName) -> MySQLQuery.ColumnDefinition {
        return .init(name: field.name, typeName: type, constraints: [])
    }
    
    /// See `SchemaSupporting`.
    public static func schemaFieldCreate(_ field: MySQLQuery.ColumnDefinition, to query: inout MySQLQuery.FluentSchema) {
        query.columns.append(field)
    }
    
    /// See `SchemaSupporting`.
    public static func schemaFieldDelete(_ field: MySQLQuery.QualifiedColumnName, to query: inout MySQLQuery.FluentSchema) {
        fatalError("MySQL does not yet support deleting columns from tables.")
    }
    
    /// See `SchemaSupporting`.
    public static func schemaReference(from: MySQLQuery.QualifiedColumnName, to: MySQLQuery.QualifiedColumnName, onUpdate: MySQLQuery.ForeignKeyReference.Action?, onDelete: MySQLQuery.ForeignKeyReference.Action?) -> MySQLQuery.TableConstraint {
        let uid = from.readable + "+" + to.readable
        return try! .init(
            name:  "fk:" + SHA1.hash(uid).hexEncodedString(),
            .foreignKey(.init(
                columns: [from.name],
                reference: .init(
                    foreignTable: .init(name: to.table!),
                    foreignColumns: [to.name],
                    onDelete: onDelete,
                    onUpdate: onUpdate,
                    match: nil,
                    deferrence: nil
                )
            ))
        )
    }
    
    /// See `SchemaSupporting`.
    public static func schemaUnique(on: [MySQLQuery.QualifiedColumnName]) -> MySQLQuery.TableConstraint {
        let uid = on.map { $0.readable }.joined(separator: "+")
        return try! .init(
            name: "uq:" + SHA1.hash(uid).hexEncodedString(),
            .unique(.init(
                columns: on.map { .init(value: .column($0.name)) },
                conflictResolution: nil
            ))
        )
    }
    
    /// See `SchemaSupporting`.
    public static func schemaConstraintCreate(_ constraint: MySQLQuery.TableConstraint, to query: inout MySQLQuery.FluentSchema) {
        query.constraints.append(constraint)
    }
    
    /// See `SchemaSupporting`.
    public static func schemaConstraintDelete(_ constraint: MySQLQuery.TableConstraint, to query: inout MySQLQuery.FluentSchema) {
        fatalError("MySQL does not support deleting constraints from tables.")
    }
    
    /// See `SchemaSupporting`.
    public static func schemaExecute(_ fluent: MySQLQuery.FluentSchema, on conn: MySQLConnection) -> Future<Void> {
        let query: MySQLQuery
        switch fluent.statement {
        case .create:
            query = .createTable(.init(
                temporary: false,
                ifNotExists: false,
                table: fluent.table,
                source: .schema(.init(
                    columns: fluent.columns,
                    tableConstraints: fluent.constraints,
                    withoutRowID: false
                ))
            ))
        case .alter:
            guard fluent.columns.count == 1 && fluent.constraints.count == 0 else {
                /// See https://www.sqlite.org/lang_altertable.html
                fatalError("MySQL only supports adding one (1) column in an ALTER query.")
            }
            query = .alterTable(.init(
                table: fluent.table,
                value: .addColumn(fluent.columns[0])
            ))
        case .drop:
            query = .dropTable(.init(
                table: fluent.table,
                ifExists: false
            ))
        }
        return conn.query(query).transform(to: ())
    }
    
    /// See `SchemaSupporting`.
    public static func enableReferences(on conn: MySQLConnection) -> Future<Void> {
        return conn.future(())
    }
    
    /// See `SchemaSupporting`.
    public static func disableReferences(on conn: MySQLConnection) -> Future<Void> {
        return conn.future(())
    }
}
