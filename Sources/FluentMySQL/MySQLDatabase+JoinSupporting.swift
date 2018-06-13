extension MySQLDatabase: JoinSupporting {
    /// See `JoinSupporting`.
    public typealias QueryJoin = MySQLQuery.JoinClause.Join
    
    /// See `JoinSupporting`.
    public typealias QueryJoinMethod = MySQLQuery.JoinClause.Join.Operator
    
    /// See `JoinSupporting`.
    public static var queryJoinMethodDefault: MySQLQuery.JoinClause.Join.Operator {
        return .inner
    }
    
    /// See `JoinSupporting`.
    public static func queryJoin(_ method: MySQLQuery.JoinClause.Join.Operator, base: MySQLQuery.QualifiedColumnName, joined: MySQLQuery.QualifiedColumnName) -> MySQLQuery.JoinClause.Join {
        return .init(
            natural: false,
            method,
            table: .table(.init(table: .init(table: .init(name: joined.table!)))),
            constraint: .condition(.binary(.column(base), .equal, .column(joined)))
        )
    }
    
    /// See `JoinSupporting`.
    public static func queryJoinApply(_ join: MySQLQuery.JoinClause.Join, to query: inout MySQLQuery.FluentQuery) {
        query.joins.append(join)
    }
}
