/// Adds ability to do basic Fluent queries using a `MySQLDatabase`.
extension MySQLDatabase: SQLDatabase {
    /// See `SQLDatabase`.
    public static func execute(query: SQLQuery, into handler: @escaping ([MySQLColumn: MySQLData], MySQLConnection) throws -> (), on conn: MySQLConnection) -> Future<Void> {
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
            if M.ID.self == Int.self && model.fluentID == nil {
                return conn.simpleQuery("SELECT LAST_INSERT_ID() AS lastval;").map { row in
                    var model = model
                    try model.fluentID = row[0].firstValue(forColumn: "lastval")?.decode(Int.self) as? M.ID
                    return model
                }
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
