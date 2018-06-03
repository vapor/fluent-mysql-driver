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
    public typealias QueryJoin = SQLQuery.DML.Join
    
    /// See `SQLDatabase`.
    public typealias QueryJoinMethod = SQLQuery.DML.Join.Method
    
    /// See `SQLDatabase`.
    public typealias Query = SQLQuery.DML
    
    /// See `SQLDatabase`.
    public typealias Output = [MySQLColumn: MySQLData]
    
    /// See `SQLDatabase`.
    public typealias QueryAction = SQLQuery.DML.Statement
    
    /// See `SQLDatabase`.
    public typealias QueryAggregate = String
    
    /// See `SQLDatabase`.
    public typealias QueryData = [SQLQuery.DML.Column: SQLQuery.DML.Value]
    
    /// See `SQLDatabase`.
    public typealias QueryField = SQLQuery.DML.Column
    
    /// See `SQLDatabase`.
    public typealias QueryFilterMethod = SQLQuery.DML.Predicate.Comparison
    
    /// See `SQLDatabase`.
    public typealias QueryFilterValue = SQLQuery.DML.Value
    
    /// See `SQLDatabase`.
    public typealias QueryFilter = SQLQuery.DML.Predicate
    
    /// See `SQLDatabase`.
    public typealias QueryFilterRelation = SQLQuery.DML.Predicate.Relation
    
    /// See `SQLDatabase`.
    public typealias QueryKey = SQLQuery.DML.Key
    
    /// See `SQLDatabase`.
    public typealias QuerySort = SQLQuery.DML.OrderBy
    
    /// See `SQLDatabase`.
    public typealias QuerySortDirection = SQLQuery.DML.OrderBy.Direction
    
    /// See `SQLDatabase`.
    public static func queryExecute(_ dml: SQLQuery.DML, on conn: MySQLConnection, into handler: @escaping ([MySQLColumn: MySQLData], MySQLConnection) throws -> ()) -> Future<Void> {
        do {
            // Create a MySQL-flavored SQL serializer to create a SQL string
            var binds = Binds()
            let sql = MySQLSerializer().serialize(dml: dml, binds: &binds)

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
    public static func queryDecode<D>(_ data: [MySQLColumn: MySQLData], entity: String, as decodable: D.Type, on conn: MySQLConnection) -> Future<D>
        where D: Decodable
    {
        do {
            let decoded = try MySQLRowDecoder().decode(D.self, from: data.filter { $0.key.table == nil || $0.key.table == entity })
            return conn.future(decoded)
        } catch {
            return conn.future(error: error)
        }
    }

    /// See `SQLDatabase`.
    public static func enableReferences(on connection: MySQLConnection) -> Future<Void> {
        return connection.simpleQuery("SET foreign_key_checks = 1;").transform(to: ())
    }

    /// See `SQLSupporting`.
    public static func disableReferences(on connection: MySQLConnection) -> Future<Void> {
        return connection.simpleQuery("SET foreign_key_checks = 0;").transform(to: ())
    }

    /// See `SQLSupporting`.
    public static func schemaColumnType(for type: Any.Type, primaryKey: Bool) -> SQLQuery.DDL.ColumnDefinition.ColumnType {
        let dataType: MySQLDataType
        if let representable = type as? MySQLColumnDefinitionStaticRepresentable.Type {
            dataType = representable.mySQLColumnDefinition
        } else {
            dataType = .json()
        }
        var columnType = SQLQuery.DDL.ColumnDefinition.ColumnType(
            name: dataType.name,
            parameters: dataType.parameters,
            attributes: dataType.attributes
        )
        if primaryKey {
            columnType.attributes.append("PRIMARY KEY")
            if columnType.name.contains("INT") {
                columnType.attributes.append("AUTO_INCREMENT")
            }
        }
        return columnType
    }

    /// See `SQLDatabase`.
    public static func schemaExecute(_ ddl: SQLQuery.DDL, on conn: MySQLConnection) -> Future<Void> {
        let sqlString = MySQLSerializer().serialize(ddl: ddl)
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
