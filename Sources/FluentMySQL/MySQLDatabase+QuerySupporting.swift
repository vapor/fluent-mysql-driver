extension MySQLDatabase: QuerySupporting {
    /// See `QuerySupporting`.
    public typealias Query = FluentMySQLQuery
    
    /// See `QuerySupporting`.
    public typealias Output = [MySQLColumn: MySQLData]
    
    /// See `QuerySupporting`.
    public typealias QueryAction = FluentMySQLQueryStatement
    
    /// See `QuerySupporting`.
    public typealias QueryAggregate = String
    
    /// See `QuerySupporting`.
    public typealias QueryData = [String: MySQLExpression]
    
    /// See `QuerySupporting`.
    public typealias QueryField = MySQLColumnIdentifier
    
    /// See `QuerySupporting`.
    public typealias QueryFilterMethod = MySQLBinaryOperator
    
    /// See `QuerySupporting`.
    public typealias QueryFilterValue = MySQLExpression
    
    /// See `QuerySupporting`.
    public typealias QueryFilter = MySQLExpression
    
    /// See `QuerySupporting`.
    public typealias QueryFilterRelation = MySQLBinaryOperator
    
    /// See `QuerySupporting`.
    public typealias QueryKey = MySQLSelectExpression
    
    /// See `QuerySupporting`.
    public typealias QuerySort = MySQLOrderBy
    
    /// See `QuerySupporting`.
    public typealias QuerySortDirection = MySQLDirection

    /// See `QuerySupporting`.
    public static func queryExecute(_ fluent: FluentMySQLQuery, on conn: MySQLConnection, into handler: @escaping ([MySQLColumn : MySQLData], MySQLConnection) throws -> ()) -> Future<Void> {
        let query: MySQLQuery
        switch fluent.statement {
        case ._insert:
            var insert: MySQLInsert = .insert(fluent.table)
            
            if let firstRow = fluent.values.first {
                insert.columns.append(contentsOf: firstRow.columns())
                fluent.values.forEach { value in
                    let row = value.mysqlExpression()
                    insert.values.append(row)
                }
            }
            
            insert.ignore = fluent.ignore
            insert.upsert = fluent.upsert
            query = .insert(insert)
        case ._select:
            var select: MySQLSelect = .select()
            select.columns = fluent.keys.isEmpty ? [.all] : fluent.keys
            select.tables = [fluent.table]
            select.joins = fluent.joins
            select.predicate = fluent.predicate
            select.orderBy = fluent.orderBy
            select.groupBy = fluent.groupBy
            select.limit = fluent.limit
            select.offset = fluent.offset
            query = .select(select)
        case ._update:
            var update: MySQLUpdate = .update(fluent.table)
            update.table = fluent.table
            if let row = fluent.values.first {
                update.values = row.map { val in (.identifier(val.key), val.value) }
            }
            update.predicate = fluent.predicate
            query = .update(update)
        case ._delete:
            var delete: MySQLDelete = .delete(fluent.table)
            delete.predicate = fluent.predicate
            query = .delete(delete)
        }
        return conn.query(query) { try handler($0, conn) }
    }

    /// See `QuerySupporting`.
    public static func modelEvent<M>(event: ModelEvent, model: M, on conn: MySQLConnection) -> EventLoopFuture<M> where MySQLDatabase == M.Database, M : Model {
        var copy = model
        switch event {
        case .willCreate:
            if M.ID.self is UUID.Type, copy.fluentID == nil {
                copy.fluentID = UUID() as? M.ID
            }
        case .didCreate:
            if let idType = M.ID.self as? UInt64Initializable.Type, copy.fluentID == nil {
                // FIXME: support other Int types
                copy.fluentID = conn.lastMetadata?.lastInsertID.flatMap(idType.init) as? M.ID
            }
        default: break
        }
        return conn.future(copy)
    }
}

internal protocol UInt64Initializable {
    init(_ uint64: UInt64)
}

extension Int: UInt64Initializable { }
extension Int32: UInt64Initializable { }
extension Int64: UInt64Initializable { }
extension UInt32: UInt64Initializable { }
extension UInt64: UInt64Initializable { }
extension UInt: UInt64Initializable { }

extension Dictionary where Key == String, Value == FluentMySQLQuery.Expression {
    func mysqlExpression() -> [MySQLExpression] {
        return self.map { pair -> MySQLExpression in
            switch pair.value {
            case ._literal(let literal):
                switch literal {
                case ._null: return .literal(.default)
                default: return pair.value
                }
            default: return pair.value
            }
        }
    }
    
    func columns() -> [MySQLColumnIdentifier] {
        return self.map { .column(nil, .identifier($0.key)) }
    }
}
