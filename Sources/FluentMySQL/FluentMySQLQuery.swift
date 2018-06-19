public enum FluentMySQLQueryStatement: FluentSQLQueryStatement {
    public static var insert: FluentMySQLQueryStatement { return ._insert }
    public static var select: FluentMySQLQueryStatement { return ._select }
    public static var update: FluentMySQLQueryStatement { return ._update }
    public static var delete: FluentMySQLQueryStatement { return ._delete }

    public var isInsert: Bool {
        switch self {
        case ._insert: return true
        default: return false
        }
    }

    case _insert
    case _select
    case _update
    case _delete
}

public struct FluentMySQLQuery: FluentSQLQuery {
    public typealias Statement = FluentMySQLQueryStatement
    public typealias TableIdentifier = MySQLTableIdentifier
    public typealias Expression = MySQLExpression
    public typealias SelectExpression = MySQLSelectExpression
    public typealias Join = MySQLJoin
    public typealias OrderBy = MySQLOrderBy
    public typealias GroupBy = MySQLGroupBy
    public typealias Upsert = MySQLUpsert

    public var statement: Statement
    public var ignore: Bool
    public var table: TableIdentifier
    public var keys: [SelectExpression]
    public var values: [String : Expression]
    public var joins: [Join]
    public var predicate: Expression?
    public var orderBy: [OrderBy]
    public var groupBy: [GroupBy]
    public var limit: Int?
    public var offset: Int?
    public var upsert: MySQLUpsert?
    public var defaultBinaryOperator: GenericSQLBinaryOperator

    public static func query(_ statement: Statement, _ table: TableIdentifier) -> FluentMySQLQuery {
        return .init(
            statement: statement,
            ignore: false,
            table: table,
            keys: [],
            values: [:],
            joins: [],
            predicate: nil,
            orderBy: [],
            groupBy: [],
            limit: nil,
            offset: nil,
            upsert: nil,
            defaultBinaryOperator: .and
        )
    }
}
