public struct MySQLQuery: SQLQuery {
    /// See `SQLQuery`.
    public var table: String

    /// See `SQLQuery`.
    public var statement: SQLStatement

    /// See `SQLQuery`.
    public var binds: [SQLValue]

    /// See `SQLQuery`.
    public var data: [DataColumn: SQLValue]

    /// See `SQLQuery`.
    public var predicates: [DataPredicateItem]

    /// See `SQLQuery`.
    public var columns: [DataQueryColumn]

    /// See `SQLQuery`.
    public var limit: Int?

    /// See `SQLQuery`.
    public var offset: Int?

    /// See `SQLQuery`.
    public var orderBys: [DataOrderBy]

    /// See `SQLQuery`.
    public var groupBys: [DataGroupBy]

    /// See `SQLQuery`.
    public var joins: [DataJoin]

    /// See `SQLQuery`.
    public init(table: String) {
        self.table = table
        self.statement = .select
        self.binds = []
        self.data = [:]
        self.predicates = []
        self.columns = []
        self.limit = nil
        self.offset = nil
        self.orderBys = []
        self.groupBys = []
        self.joins = []
    }
}

/// Adds ability to do basic Fluent queries using a `MySQLDatabase`.
extension MySQLDatabase: SQLDatabase {
    /// See `SQLDatabase`.
    public static func execute(
        query: MySQLQuery,
        into handler: @escaping ([MySQLColumn: MySQLData], MySQLConnection) throws -> (),
        on conn: MySQLConnection
    ) -> Future<Void> {
        do {
            // Create a MySQL-flavored SQL serializer to create a SQL string
            let sqlSerializer = MySQLSerializer()
            let sqlString = sqlSerializer.serialize(query)

            // Convert the data and bound filter parameters
            let params = try query.data.values.convertToMySQLData() + query.binds.convertToMySQLData()

            /// If a logger exists, log the query
            if let logger = conn.logger {
                logger.record(query: sqlString, values: params.map { $0.description })
            }

            /// Run the query!
            return conn.query(sqlString, params) { row in
                try handler(row, conn)
            }
        } catch {
            return conn.eventLoop.newFailedFuture(error: error)
        }
    }

    /// See `SQLDatabase`.
    public static func modelEvent<M>(event: ModelEvent, model: M, on conn: MySQLConnection) -> Future<M>
        where MySQLDatabase == M.Database, M: Model
    {
        switch event {
        case .willCreate:
            if M.ID.self == UUID.self && model.fluentID == nil {
                var model = model
                model.fluentID = UUID() as? M.ID
                return conn.eventLoop.newSucceededFuture(result: model)
            }
        case .didCreate:
            if let metadata = conn.lastMetadata, let insertID = metadata.lastInsertID, M.ID.self == Int.self && model.fluentID == nil {
                var model = model
                model.fluentID = Int(insertID) as? M.ID
                return conn.eventLoop.newSucceededFuture(result: model)
            }
        default: break
        }

        return conn.eventLoop.newSucceededFuture(result: model)
    }

    /// See `QuerySupporting`.
    public static func queryDecode<D>(_ data: [MySQLColumn: MySQLData], entity: String, as decodable: D.Type) throws -> D
        where D: Decodable
    {
        return try MySQLRowDecoder().decode(D.self, from: data.filter { $0.key.table == nil || $0.key.table == entity })
    }
}

extension Collection where Element == SQLValue {
    func convertToMySQLData() throws -> [MySQLData] {
        return try map { value in
            switch value {
            case .encodable(let encodable):
                guard let convertible = encodable as? MySQLDataConvertible else {
                    fatalError("`\(Swift.type(of: encodable))` is not `MySQLDataConvertible`.")
                }

                return try convertible.convertToMySQLData()
            }
        }
    }
}
