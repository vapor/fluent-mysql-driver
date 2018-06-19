extension QueryBuilder where Result.Database == MySQLDatabase, Result: Model, Result.Database == Database {
    public func create(orIgnore: Bool, _ model: Result) -> Future<Result> {
        query.ignore = true
        return create(model)
    }
}

extension Model where Database == MySQLDatabase {
    public func create(orIgnore: Bool, on conn: DatabaseConnectable) -> Future<Self> {
        return Self.query(on: conn).create(orIgnore: orIgnore, self)
    }
}
