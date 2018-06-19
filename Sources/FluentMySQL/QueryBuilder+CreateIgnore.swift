extension Model where Database.Query == FluentMySQLQuery {
    public func create(orIgnore: Bool, on conn: DatabaseConnectable) -> Future<Self> {
        return Self.query(on: conn).create(orIgnore: orIgnore, self)
    }
}

extension QueryBuilder where Result: Model, Result.Database == Database, Result.Database.Query == FluentMySQLQuery {
    public func create(orIgnore: Bool, _ model: Result) -> Future<Result> {
        query.ignore = true
        return create(model)
    }
}
