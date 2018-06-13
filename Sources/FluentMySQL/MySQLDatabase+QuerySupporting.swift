extension MySQLQuery {
    public struct FluentQuery {
        public enum Statement {
            case insert(orIgnore: Bool)
            case select
            case update
            case delete
        }
        
        public enum Comparison {
            case binary(Expression.BinaryOperator)
            case subset(Expression.SubsetOperator)
            case compare(Expression.Compare.Operator)
        }
        
        public var statement: Statement
        public var table: TableName
        public var joins: [JoinClause.Join]
        public var keys: [MySQLQuery.Select.ResultColumn]
        public var values: [String: MySQLQuery.Expression]
        public var predicate: Expression?
        public var limit: Int?
        public var offset: Int?
        public var defaultRelation: Expression.BinaryOperator
        public var upsert: MySQLQuery.Insert.UpsertClause?
        public init(_ statement: Statement, table: TableName) {
            self.statement = statement
            self.table = table
            self.joins = []
            self.keys = []
            self.values = [:]
            self.predicate = nil
            self.limit = nil
            self.offset = nil
            defaultRelation = .and
            self.upsert = nil
        }
    }
}

extension MySQLDatabase: QuerySupporting {
    /// See `QuerySupporting`.
    public typealias Query = MySQLQuery.FluentQuery
    
    /// See `QuerySupporting`.
    public typealias Output = [MySQLColumn: MySQLData]
    
    /// See `QuerySupporting`.
    public typealias QueryAction = MySQLQuery.FluentQuery.Statement
    
    /// See `QuerySupporting`.
    public typealias QueryAggregate = String
    
    /// See `QuerySupporting`.
    public typealias QueryData = [String: MySQLQuery.Expression]
    
    /// See `QuerySupporting`.
    public typealias QueryField = MySQLQuery.QualifiedColumnName
    
    /// See `QuerySupporting`.
    public typealias QueryFilterMethod = MySQLQuery.FluentQuery.Comparison
    
    /// See `QuerySupporting`.
    public typealias QueryFilterValue = MySQLQuery.Expression
    
    /// See `QuerySupporting`.
    public typealias QueryFilter = MySQLQuery.Expression
    
    /// See `QuerySupporting`.
    public typealias QueryFilterRelation = MySQLQuery.Expression.BinaryOperator
    
    /// See `QuerySupporting`.
    public typealias QueryKey = MySQLQuery.Select.ResultColumn
    
    /// See `QuerySupporting`.
    public typealias QuerySort = String
    
    /// See `QuerySupporting`.
    public typealias QuerySortDirection = MySQLQuery.Direction
    
    public static func query(_ entity: String) -> MySQLQuery.FluentQuery {
        return .init(.select, table: .init(name: entity))
    }
    
    public static func queryEntity(for query: MySQLQuery.FluentQuery) -> String {
        return query.table.name
    }
    
    public static func queryExecute(_ fluent: MySQLQuery.FluentQuery, on conn: MySQLConnection, into handler: @escaping ([MySQLColumn : MySQLData], MySQLConnection) throws -> ()) -> Future<Void> {
        let query: MySQLQuery
        switch fluent.statement {
        case .insert(let orIgnore):
            // filter out all `NULL` values, no need to insert them since
            // they could override default values that we want to keep
            let values = fluent.values.filter { (key, val) in
                switch val {
                case .literal(let literal) where literal == .null: return false
                default: return true
                }
            }
            query = .insert(.init(
                with: nil,
                conflictResolution: orIgnore ? .ignore : nil,
                table: .init(table: fluent.table, alias: nil),
                columns: values.keys.map { .init($0) },
                values: .values([.init(values.values)]),
                upsert: fluent.upsert
            ))
        case .select:
            var table: MySQLQuery.TableOrSubquery
            switch fluent.joins.count {
            case 0: table = .table(.init(table: .init(table: fluent.table, alias: nil), indexing: nil))
            default:
                table = .joinClause(.init(
                    table: .table(.init(table: .init(table: fluent.table, alias: nil), indexing: nil)),
                    joins: fluent.joins
                ))
            }
            
            query = .select(.init(
                with: nil,
                distinct: nil,
                columns: fluent.keys.isEmpty ? [.all(nil)] : fluent.keys,
                tables: [table],
                predicate: fluent.predicate
            ))
        case .update:
            query = .update(.init(
                with: nil,
                conflictResolution: nil,
                table: .init(table: .init(table: fluent.table, alias: nil), indexing: nil),
                values: .init(columns: fluent.values.map { (col, expr) in
                    return .init(columns: [.init(col)], value: expr)
                }, predicate: nil),
                predicate: fluent.predicate
            ))
        case .delete:
            query = .delete(.init(
                with: nil,
                table: .init(table: .init(table: fluent.table, alias: nil), indexing: nil),
                predicate: fluent.predicate
            ))
        }
        return conn.query(query) { try handler($0, conn) }
    }
    
    public static func queryDecode<D>(_ output: [MySQLColumn : MySQLData], entity: String, as decodable: D.Type, on conn: MySQLConnection) -> Future<D> where D : Decodable {
        do {
            return try conn.future(output.decode(D.self, from: entity))
        } catch {
            return conn.future(error: error)
        }
    }
    
    public static func queryEncode<E>(_ encodable: E, entity: String) throws -> [String: MySQLQuery.Expression] where E : Encodable {
        return try MySQLQueryEncoder().encode(encodable)
    }
    
    public static func modelEvent<M>(event: ModelEvent, model: M, on conn: MySQLConnection) -> EventLoopFuture<M> where MySQLDatabase == M.Database, M : Model {
        var copy = model
        switch event {
        case .willCreate:
            if M.ID.self is UUID.Type {
                copy.fluentID = UUID() as? M.ID
            }
        case .didCreate:
            if M.ID.self is Int.Type {
                // FIXME: support other Int types
                copy.fluentID = conn.lastMetadata?.lastInsertID.flatMap(Int.init) as? M.ID
            }
        default: break
        }
        return conn.future(copy)
    }
    
    public static var queryActionCreate: MySQLQuery.FluentQuery.Statement {
        return .insert(orIgnore: false)
    }
    
    public static var queryActionRead: MySQLQuery.FluentQuery.Statement {
        return .select
    }
    
    public static var queryActionUpdate: MySQLQuery.FluentQuery.Statement {
        return .update
    }
    
    public static var queryActionDelete: MySQLQuery.FluentQuery.Statement {
        return .delete
    }
    
    public static func queryActionIsCreate(_ action: MySQLQuery.FluentQuery.Statement) -> Bool {
        switch action {
        case .insert: return true
        default: return false
        }
    }
    
    public static func queryActionApply(_ action: MySQLQuery.FluentQuery.Statement, to query: inout MySQLQuery.FluentQuery) {
        query.statement = action
    }
    
    public static var queryAggregateCount: String {
        return "COUNT"
    }
    
    public static var queryAggregateSum: String {
        return "SUM"
    }
    
    public static var queryAggregateAverage: String {
        return "AVG"
    }
    
    public static var queryAggregateMinimum: String {
        return "MIN"
    }
    
    public static var queryAggregateMaximum: String {
        return "MAX"
    }
    
    public static func queryDataSet<E>(_ field: MySQLQuery.QualifiedColumnName, to data: E, on query: inout MySQLQuery.FluentQuery)
        where E: Encodable
    {
        query.values[field.name.string] = try! .bind(data)
    }
    
    public static func queryDataApply(_ data: [String: MySQLQuery.Expression], to query: inout MySQLQuery.FluentQuery) {
        query.values = data
    }
    
    public static func queryField(_ property: FluentProperty) -> MySQLQuery.QualifiedColumnName {
        return .init(schema: nil, table: property.entity, name: .init(property.path[0]))
    }
    
    public static var queryFilterMethodEqual: MySQLQuery.FluentQuery.Comparison {
        return .binary(.equal)
    }
    
    public static var queryFilterMethodNotEqual: MySQLQuery.FluentQuery.Comparison {
        return .binary(.notEqual)
    }
    
    public static var queryFilterMethodGreaterThan: MySQLQuery.FluentQuery.Comparison {
        return .binary(.greaterThan)
    }
    
    public static var queryFilterMethodLessThan: MySQLQuery.FluentQuery.Comparison {
        return .binary(.lessThan)
    }
    
    public static var queryFilterMethodGreaterThanOrEqual: MySQLQuery.FluentQuery.Comparison {
        return .binary(.greaterThanOrEqual)
    }
    
    public static var queryFilterMethodLessThanOrEqual: MySQLQuery.FluentQuery.Comparison {
        return .binary(.lessThanOrEqual)
    }
    
    public static var queryFilterMethodInSubset: MySQLQuery.FluentQuery.Comparison {
        return .subset(.in)
    }
    
    public static var queryFilterMethodNotInSubset: MySQLQuery.FluentQuery.Comparison {
        return .subset(.notIn)
    }
    
    public static func queryFilterValue<E>(_ encodables: [E]) -> MySQLQuery.Expression
        where E: Encodable
    {
        return try! .expressions(encodables.map { try .bind($0) })
    }
    
    public static var queryFilterValueNil: MySQLQuery.Expression {
        return .literal(.null)
    }
    
    public static func queryFilter(_ field: MySQLQuery.QualifiedColumnName, _ method: MySQLQuery.FluentQuery.Comparison, _ value: MySQLQuery.Expression) -> MySQLQuery.Expression {
        switch method {
        case .binary(let binary): return .binary(.column(field), binary, value)
        case .compare(let compare): return .compare(.init(.column(field), not: false, compare, value, escape: nil))
        case .subset(let subset): return .subset(.column(field), subset, .expressions([value]))
        }
        
    }
    
    public static func queryFilters(for query: MySQLQuery.FluentQuery) -> [MySQLQuery.Expression] {
        switch query.predicate {
        case .none: return []
        case .some(let wrapped): return [wrapped]
        }
    }
    
    public static func queryFilterApply(_ filter: MySQLQuery.Expression, to query: inout MySQLQuery.FluentQuery) {
        switch query.defaultRelation {
        case .or: query.predicate |= filter
        default: query.predicate &= filter
        }
    }
    
    public static var queryFilterRelationAnd: MySQLQuery.Expression.BinaryOperator {
        return .and
    }
    
    public static var queryFilterRelationOr: MySQLQuery.Expression.BinaryOperator {
        return .or
    }
    
    
    public static func queryDefaultFilterRelation(_ relation: MySQLQuery.Expression.BinaryOperator, on query: inout MySQLQuery.FluentQuery) {
        query.defaultRelation = relation
    }
    
    public static func queryFilterGroup(_ relation: MySQLQuery.Expression.BinaryOperator, _ filters: [MySQLQuery.Expression]) -> MySQLQuery.Expression {
        var current: MySQLQuery.Expression?
        for next in filters {
            switch relation {
            case .or: current |= next
            case .and: current &= next
            default: break
            }
        }
        if let predicate = current {
            return .expressions([predicate])
        } else {
            return .expressions([])
        }
    }
    
    public static var queryKeyAll: MySQLQuery.Select.ResultColumn {
        return .all(nil)
    }
    
    public static func queryAggregate(_ aggregate: String, _ fields: [MySQLQuery.Select.ResultColumn]) -> MySQLQuery.Select.ResultColumn {
        let parameters: MySQLQuery.Expression.Function.Parameters
        switch fields.count {
        case 1:
            switch fields[0] {
            case .all: parameters = .all
            case .expression(let expr, _): parameters = .expressions(distinct: false, [expr])
            }
        default:
            parameters = .expressions(distinct: false, fields.compactMap { field in
                switch field {
                case .all: return nil
                case .expression(let expr, _): return expr
                }
            })
        }
        return .expression(.function(.init(
            name: aggregate,
            parameters: parameters
        )), alias: "fluentAggregate")
    }
    
    public static func queryKey(_ field: MySQLQuery.QualifiedColumnName) -> MySQLQuery.Select.ResultColumn {
        return .expression(.column(field), alias: nil)
    }
    
    public static func queryKeyApply(_ key: MySQLQuery.Select.ResultColumn, to query: inout MySQLQuery.FluentQuery) {
        query.keys.append(key)
    }
    
    public static func queryRangeApply(lower: Int, upper: Int?, to query: inout MySQLQuery.FluentQuery) {
        if let upper = upper {
            query.limit = upper - lower
            query.offset = lower
        } else {
            query.offset = lower
        }
    }
    
    public static func querySort(_ field: MySQLQuery.QualifiedColumnName, _ direction: MySQLQuery.Direction) -> String {
        fatalError()
    }
    
    public static var querySortDirectionAscending: MySQLQuery.Direction {
        return .ascending
    }
    
    public static var querySortDirectionDescending: MySQLQuery.Direction {
        return .descending
    }
    
    public static func querySortApply(_ sort: String, to query: inout MySQLQuery.FluentQuery) {
        fatalError()
    }
}
