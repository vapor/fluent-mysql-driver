import FluentSQL
import MySQLKit

final class MySQLDatabaseDriver: DatabaseDriver {
    var eventLoopGroup: EventLoopGroup {
        return self.pool.eventLoopGroup
    }
    
    let pool: ConnectionPool<MySQLConnectionSource>
    init(pool: ConnectionPool<MySQLConnectionSource>) {
        self.pool = pool
    }
    
    func execute(query: DatabaseQuery, database: Database, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        let sql = SQLQueryConverter(delegate: MySQLConverterDelegate()).convert(query)
        var serializer = SQLSerializer(dialect: MySQLDialect())
        sql.serialize(to: &serializer)
        let binds = serializer.binds.map { encodable in
            return try! MySQLDataEncoder().encode(encodable)
        }
        return self.pool.withConnection(eventLoop: database.eventLoopPreference.pool) { conn in
            return conn.query(serializer.sql, binds, onRow: { row in
                onRow(row)
            }, onMetadata: { metadata in
                let row = LastInsertRow(metadata: metadata)
                onRow(row)
            })
        }
    }

    func execute(schema: DatabaseSchema, database: Database) -> EventLoopFuture<Void> {
        let sql = SQLSchemaConverter(delegate: MySQLConverterDelegate()).convert(schema)
        return self.pool.withConnection(eventLoop: database.eventLoopPreference.pool) { conn in
            return conn.execute(sql: sql) { row in
                fatalError("unexpected output")
            }
        }
    }
    
    func shutdown() {
        self.pool.shutdown()
    }
}

extension EventLoopPreference {
    var pool: ConnectionPoolEventLoopPreference {
        switch self {
        case .delegate(on: let eventLoop):
            return .delegate(on: eventLoop)
        case .indifferent:
            return .indifferent
        }
    }
}

extension MySQLDatabaseDriver: SQLDatabase {
    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) throws -> ()) -> EventLoopFuture<Void> {
        return self.pool.withConnection(eventLoop: .indifferent) {
            $0.execute(sql: query, onRow)
        }
    }
}

struct LastInsertRow: DatabaseRow {
    var description: String {
        return "\(self.metadata)"
    }

    let metadata: MySQLQueryMetadata

    func contains(field: String) -> Bool {
        return field == "fluentID"
    }

    func decode<T>(field: String, as type: T.Type, for database: Database) throws -> T where T : Decodable {
        switch field {
        case "fluentID":
            if T.self is Int.Type {
                return Int(self.metadata.lastInsertID!) as! T
            } else {
                fatalError()
            }
        default: throw FluentError.missingField(name: field)
        }
    }
}
