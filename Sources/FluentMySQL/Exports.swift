@_exported import Fluent
@_exported import FluentSQL
@_exported import MySQL

extension QueryBuilder where Result: Model, Result.Database == Database, Database == MySQLDatabase {
    public func create(orIgnore: Bool, _ model: Result) -> Future<Result> {
        if orIgnore {
            return create(model, .init(verb: "INSERT", modifiers: ["IGNORE"]))
        } else {
            return create(model)
        }
    }
    public func create(orUpdate: Bool, _ model: Result) -> Future<Result> {
        return connection.flatMap { conn in
            if orUpdate {
                self.query.conflict = try .on(["id"], values: MySQLDatabase.queryEncode(model, entity: Result.entity))
            }
            return self.create(model)
        }
    }
    
    public func queryMetadata() -> Future<MySQLQueryMetadata> {
        return connection.map { conn in
            guard let metadata = conn.lastMetadata else {
                throw MySQLError(identifier: "metadata", reason: "No query metadata.", source: .capture())
            }
            return metadata
        }
    }
}

extension Model where Database == MySQLDatabase {
    public func create(orIgnore: Bool, on conn: DatabaseConnectable) throws -> Future<Self> {
        return Self.query(on: conn).create(orIgnore: orIgnore, self)
    }
    public func create(orUpdate: Bool, on conn: DatabaseConnectable) throws -> Future<Self> {
        return Self.query(on: conn).create(orUpdate: orUpdate, self)
    }
}
