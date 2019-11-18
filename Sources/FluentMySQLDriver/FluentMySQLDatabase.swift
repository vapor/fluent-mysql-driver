import FluentSQL
import MySQLKit
import AsyncKit

struct _FluentMySQLDatabase {
    let database: MySQLDatabase
    let context: DatabaseContext
}

extension _FluentMySQLDatabase: Database {
    func execute(query: DatabaseQuery, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        let expression = SQLQueryConverter(delegate: MySQLConverterDelegate())
            .convert(query)
        let (sql, binds) = self.serialize(expression)
        do {
            return try self.query(sql, binds.map { try MySQLDataEncoder().encode($0) }, onRow: onRow, onMetadata: { metadata in
                switch query.action {
                case .create:
                    onRow(LastInsertRow(metadata: metadata))
                default:
                    break
                }
            })
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let expression = SQLSchemaConverter(delegate: MySQLConverterDelegate())
            .convert(schema)
        let (sql, binds) = self.serialize(expression)
        do {
            return try self.query(sql, binds.map { try MySQLDataEncoder().encode($0) }, onRow: {
                fatalError("unexpected row: \($0)")
            })
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection {
            closure(_FluentMySQLDatabase(database: $0, context: self.context))
        }
    }
}

extension _FluentMySQLDatabase: SQLDatabase {
    var dialect: SQLDialect {
        MySQLDialect()
    }
    
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
