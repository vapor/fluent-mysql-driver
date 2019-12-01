extension Model where Database.Query == FluentMySQLQuery {
    public func create(orUpdate: Bool, on conn: DatabaseConnectable) -> Future<Self> {
        return Self.query(on: conn).create(orUpdate: orUpdate, self)
    }
}

extension QueryBuilder where Result: Model, Result.Database == Database, Result.Database.Query == FluentMySQLQuery {
    public func create(orUpdate: Bool, _ model: Result) -> Future<Result> {
        if orUpdate {
            var copy = model

            // set timestamps
            if Result.updatedAtKey != nil {
                if Result.updatedAtKey != nil, copy.fluentUpdatedAt == nil {
                    copy.fluentUpdatedAt = Date()
                }
            }
            let createdAtRowIdentifier = (try? Result.reflectProperty(forKey: \.fluentCreatedAt)?.path.first) ?? nil

            let row = SQLQueryEncoder(MySQLExpression.self).encode(copy)
            let values = row.compactMap { row -> (MySQLIdentifier, MySQLExpression)? in
                let identifier: MySQLIdentifier = .identifier(row.key)

                // We don't want to delete `createdAt` for entries that got upserted
                if Result.createdAtKey != nil && copy.fluentCreatedAt == nil && identifier.string == createdAtRowIdentifier {
                    return nil
                }
                return (identifier, row.value)
            }
            self.query.upsert = .upsert(values)
        }
        return create(model)
    }
    
}
