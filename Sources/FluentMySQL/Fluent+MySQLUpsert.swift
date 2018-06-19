extension Model where Database.Query == FluentMySQLQuery {
    public func create(orUpdate: Bool, on conn: DatabaseConnectable) -> Future<Self> {
        return Self.query(on: conn).create(orUpdate: orUpdate, self)
    }
}

extension QueryBuilder where Result: Model, Result.Database == Database, Result.Database.Query == FluentMySQLQuery {
    public func create(orUpdate: Bool, _ model: Result) -> Future<Result> {
        if orUpdate {
            let row = SQLQueryEncoder(MySQLExpression.self).encode(model)
            let values = row.map { row -> (MySQLIdentifier, MySQLExpression) in
                return (.identifier(row.key), row.value)
            }
            self.query.upsert = .upsert(values)
        }
        return create(model)
    }
    
}
