import FluentSQL
import MySQLKit
import AsyncKit

struct _FluentMySQLDatabase {
    let database: MySQLDatabase
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
        return self.query(serialized.sql, serialized.binds, onRow: onRow, onMetadata: { metadata in
            switch query.action {
            case .create:
                onRow(LastInsertRow(metadata: metadata))
            default:
                break
            }
        })
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
        return self.query(serialized.sql, serialized.binds, onRow: {
            fatalError("unexpected row: \($0)")
        })
    }
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection {
            closure(_FluentMySQLDatabase(database: $0, context: self.context))
        }
    }
}

extension _FluentMySQLDatabase: SQLDatabase {
    public func execute(
        sql query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<Void> {
        self.sql().execute(sql: query, onRow)
    }
}

extension _FluentMySQLDatabase: MySQLDatabase {
    func send(_ command: MySQLCommand, logger: Logger) -> EventLoopFuture<Void> {
        self.database.send(command, logger: logger)
    }
    
    func withConnection<T>(_ closure: @escaping (MySQLConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
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
