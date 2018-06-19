@_exported import FluentSQL
@_exported import MySQL
//
//extension QueryBuilder where Result: Model, Result.Database == Database, Database == MySQLDatabase {
//    public func create(orIgnore: Bool, _ model: Result) -> Future<Result> {
//        query.statement = .insert(orIgnore: orIgnore)
//        return _mysqlCreate(model, .insert(orIgnore: orIgnore))
//    }
//
//    public func create(orUpdate: Bool, _ model: Result) -> Future<Result> {
//        return connection.flatMap { conn in
//            if orUpdate {
//                let data = try MySQLQueryEncoder().encode(model)
//                self.query.upsert = MySQLQuery.Insert.UpsertClause(
//                    values: .init(columns: data.map { col -> MySQLQuery.SetValues.ColumnGroup in
//                        return .init(columns: [MySQLQuery.ColumnName(col.0)], value: col.1)
//                    })
//                )
//            }
//            return self._mysqlCreate(model, .insert(orIgnore: false))
//        }
//    }
//
//    private func _mysqlCreate(_ model: Result, _ statement: MySQLQuery.FluentQuery.Statement) -> Future<Result> {
//        var copy: Result
//        if Result.createdAtKey != nil || Result.updatedAtKey != nil {
//            // set timestamps
//            copy = model
//            let now = Date()
//            copy.fluentUpdatedAt = now
//            copy.fluentCreatedAt = now
//        } else {
//            copy = model
//        }
//
//        return connection.flatMap { conn in
//            return Database.modelEvent(event: .willCreate, model: copy, on: conn).flatMap { model in
//                return try model.willCreate(on: conn)
//                }.flatMap { model -> Future<Result> in
//                    var copy = model
//                    try Database.queryDataApply(Database.queryEncode(copy, entity: Result.entity), to: &self.query)
//                    return self.run(statement) {
//                        // to support reference types that may be ignoring return values
//                        // set the id on the existing value before replacing it
//                        copy.fluentID = $0.fluentID
//                        // if a model is returned, use it since it may have default values
//                        copy = $0
//                    }.map { copy }
//                }.flatMap { model in
//                    return Database.modelEvent(event: .didCreate, model: model, on: conn)
//                }.flatMap { model in
//                    return try model.didCreate(on: conn)
//            }
//        }
//    }
//    public func queryMetadata() -> Future<MySQLConnection.Metadata> {
//        return connection.map { conn in
//            guard let metadata = conn.lastMetadata else {
//                throw MySQLError(identifier: "metadata", reason: "No query metadata.", source: .capture())
//            }
//            return metadata
//        }
//    }
//}
//
//extension Model where Database == MySQLDatabase {
//    public func create(orIgnore: Bool, on conn: DatabaseConnectable) -> Future<Self> {
//        return Self.query(on: conn).create(orIgnore: orIgnore, self)
//    }
//    public func create(orUpdate: Bool, on conn: DatabaseConnectable) -> Future<Self> {
//        return Self.query(on: conn).create(orUpdate: orUpdate, self)
//    }
//}
