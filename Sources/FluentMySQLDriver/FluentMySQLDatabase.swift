import FluentSQL
import MySQLKit
import AsyncKit

struct _FluentMySQLDatabase {
    let pool: EventLoopConnectionPool<MySQLConnectionSource>
    let context: DatabaseContext
}

extension _FluentMySQLDatabase: Database {
    func execute(query: DatabaseQuery, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        let sql = SQLQueryConverter(delegate: MySQLConverterDelegate())
            .convert(query)
        let serialized: (sql: String, binds: [MySQLData])
        do {
            serialized = try mysqlSerialize(sql)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.pool.withConnection(logger: self.logger) {
            $0.logging(to: self.logger)
                .query(serialized.sql, serialized.binds, onRow: onRow)
        }
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let sql = SQLSchemaConverter(delegate: MySQLConverterDelegate())
            .convert(schema)
        let serialized: (sql: String, binds: [MySQLData])
        do {
            serialized = try mysqlSerialize(sql)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.pool.withConnection(logger: self.logger) {
            $0.logging(to: self.logger)
                .query(serialized.sql, serialized.binds, onRow: {
                    fatalError("unexpected row: \($0)")
                })
        }
    }
}

extension _FluentMySQLDatabase: SQLDatabase {
    public func execute(
        sql query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: self.logger) {
            $0.logging(to: self.logger)
                .sql()
                .execute(sql: query, onRow)
        }
    }
}

extension _FluentMySQLDatabase: MySQLDatabase {
    func send(_ command: MySQLCommand, logger: Logger) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: logger) {
            $0.send(command, logger: logger)
        }
    }
    
    
}

private struct LastInsertRow: DatabaseRow {
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

private func mysqlSerialize(_ sql: SQLExpression) throws -> (String, [MySQLData]) {
    var serializer = SQLSerializer(dialect: MySQLDialect())
    sql.serialize(to: &serializer)
    let binds: [MySQLData]
    binds = try serializer.binds.map { encodable in
        return try MySQLDataEncoder().encode(encodable)
    }
    return (serializer.sql, binds)
}
