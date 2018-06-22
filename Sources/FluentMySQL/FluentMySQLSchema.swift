public enum FluentMySQLSchemaStatement: FluentSQLSchemaStatement {
    public static var createTable: FluentMySQLSchemaStatement { return ._createTable }
    public static var alterTable: FluentMySQLSchemaStatement { return ._alterTable }
    public static var dropTable: FluentMySQLSchemaStatement { return ._dropTable }

    case _createTable
    case _alterTable
    case _dropTable
}

public struct FluentMySQLSchema: FluentSQLSchema {
    public typealias Statement = FluentMySQLSchemaStatement
    public typealias TableIdentifier = MySQLTableIdentifier
    public typealias ColumnDefinition = MySQLColumnDefinition
    public typealias TableConstraint = MySQLTableConstraint

    public var statement: Statement
    public var table: TableIdentifier
    public var columns: [MySQLColumnDefinition]
    public var deleteColumns: [MySQLColumnIdentifier]
    public var constraints: [MySQLTableConstraint]
    public var deleteConstraints: [MySQLTableConstraint]
    public var columnPositions: [ColumnDefinition.ColumnIdentifier: MySQLAlterTable.ColumnPosition]

    public static func schema(_ statement: Statement, _ table: TableIdentifier) -> FluentMySQLSchema {
        return .init(
            statement: statement,
            table: table,
            columns: [],
            deleteColumns: [],
            constraints: [],
            deleteConstraints: [],
            columnPositions: [:]
        )
    }
}
