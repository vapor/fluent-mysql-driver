extension MySQLData: Encodable {
    /// See `Encodable`.
    public func encode(to encoder: Encoder) throws {
        var single = encoder.singleValueContainer()
        try single.encode(data() ?? .init())
    }
}

/// Adds ability to create, update, and delete schemas using a `MySQLDatabase`.
extension MySQLDatabase: SQLSupporting & LogSupporting & TransactionSupporting {
    /// See `SQLDatabase`.
    public static func queryExecute(_ query: DataManipulationQuery, on conn: MySQLConnection, into handler: @escaping ([MySQLColumn : MySQLData], MySQLConnection) throws -> ()) -> EventLoopFuture<Void> {
        do {
            // Create a MySQL-flavored SQL serializer to create a SQL string
            var binds = Binds()
            let sql = MySQLSerializer().serialize(query: query, binds: &binds)

            // Convert binds to MySQL data
            let parameters = try binds.values.map { encodable -> MySQLData in
                guard let mysqlData = encodable as? MySQLDataConvertible else {
                    throw MySQLError(identifier: "mysqlData", reason: "`\(type(of: encodable))` does not conform to `MySQLDataConvertible`. ", source: .capture())
                }
                return try mysqlData.convertToMySQLData()
            }

            /// If a logger exists, log the query
            if let logger = conn.logger {
                logger.record(query: sql, values: parameters.map { $0.description })
            }

            /// Run the query!
            return conn.query(sql, parameters) { row in
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

    /// See `SQLDatabase`.
    public static func queryEncode<E>(_ encodable: E, entity: String) throws -> [DataManipulationColumn] where E : Encodable {
        let row = try MySQLRowEncoder().encode(encodable)
        return row.map { (row) -> DataManipulationColumn in
            if row.value.isNull {
                return .init(column: .init(table: row.key.table, name: row.key.name), value: .null)
            } else {
                return .init(column: .init(table: row.key.table, name: row.key.name), value: .binds([row.value]))
            }
        }
    }

    /// See `SQLDatabase`.
    public static func queryDecode<D>(_ data: [MySQLColumn: MySQLData], entity: String, as decodable: D.Type) throws -> D
        where D: Decodable
    {
        return try MySQLRowDecoder().decode(D.self, from: data.filter { $0.key.table == nil || $0.key.table == entity })
    }

    /// See `SQLDatabase`.
    public static func enableReferences(on connection: MySQLConnection) -> Future<Void> {
        return connection.simpleQuery("SET foreign_key_checks = 1;").transform(to: ())
    }

    /// See `SQLDatabase`.
    public static func disableReferences(on connection: MySQLConnection) -> Future<Void> {
        return connection.simpleQuery("SET foreign_key_checks = 0;").transform(to: ())
    }

    public static func schemaDataType(for type: Any.Type, primaryKey: Bool) -> DataDefinitionDataType {
        guard let representable = type as? MySQLColumnDefinitionStaticRepresentable.Type else {
            fatalError("""
            No MySQL column type known for `\(type)`.

            Suggested Fixes:
                - Conform \(type) to `MySQLColumnDefinitionStaticRepresentable` to specify field type or implement a custom migration.
                - Specify the `MySQLColumnDefinition` manually using the schema builder in a migration.
            """)
        }
        var mysqlDataType = representable.mySQLColumnDefinition
        if primaryKey {
            mysqlDataType.addPrimaryKeyAttributes()
        }
        return mysqlDataType.dataType
    }

    /// See `SQLDatabase`.
    public static func schemaExecute(_ schema: DataDefinitionQuery, on conn: MySQLConnection) -> Future<Void> {
        let sqlString = MySQLSerializer().serialize(query: schema)
        if let logger = conn.logger {
            logger.log(query: sqlString)
        }
        return conn.simpleQuery(sqlString).transform(to: ())
    }

    /// See `LogSupporting`.
    public static func enableLogging(_ logger: DatabaseLogger, on conn: MySQLConnection) {
        conn.logger = logger
    }


    /// See `TransactionSupporting`.
    public static func transactionExecute<T>(_ transaction: @escaping (MySQLConnection) throws -> Future<T>, on conn: MySQLConnection) -> Future<T> {
        return conn.simpleQuery("START TRANSACTION").flatMap { _ -> Future<T> in
            return try transaction(conn).flatMap { res -> Future<T> in
                return conn.simpleQuery("COMMIT").transform(to: res)
            }
        }.catchFlatMap { error in
            return conn.simpleQuery("ROLLBACK").map { _ in
                throw error
            }
        }
    }
}
