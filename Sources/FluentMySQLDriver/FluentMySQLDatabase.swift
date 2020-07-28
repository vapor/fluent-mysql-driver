import FluentSQL
import MySQLKit
import AsyncKit

struct _FluentMySQLDatabase {
    let database: MySQLDatabase
    let encoder: MySQLDataEncoder
    let decoder: MySQLDataDecoder
    let context: DatabaseContext
    let inTransaction: Bool
}

extension _FluentMySQLDatabase: Database {
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {
        let expression = SQLQueryConverter(delegate: MySQLConverterDelegate())
            .convert(query)
        let (sql, binds) = self.serialize(expression)
        do {
            return try self.query(
                sql, binds.map { try self.encoder.encode($0) },
                onRow: { row in
                    onOutput(row.databaseOutput(decoder: self.decoder))
                },
                onMetadata: { metadata in
                    switch query.action {
                    case .create:
                        let row = LastInsertRow(
                            metadata: metadata,
                            customIDKey: query.customIDKey
                        )
                        onOutput(row)
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

    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }

    func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        guard !self.inTransaction else {
            return closure(self)
        }
        return self.database.withConnection { conn in
            conn.simpleQuery("START TRANSACTION").flatMap { _ in
                let db = _FluentMySQLDatabase(
                    database: conn,
                    encoder: self.encoder,
                    decoder: self.decoder,
                    context: self.context,
                    inTransaction: true
                )
                return closure(db).flatMap { result in
                    conn.simpleQuery("COMMIT").map { _ in
                        result
                    }
                }.flatMapError { error in
                    conn.simpleQuery("ROLLBACK").flatMapThrowing { _ in
                        throw error
                    }
                }
            }
        }
    }
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection {
            closure(_FluentMySQLDatabase(
                database: $0,
                encoder: self.encoder,
                decoder: self.decoder,
                context: self.context,
                inTransaction: self.inTransaction
            ))
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

private struct LastInsertRow: DatabaseOutput {
    var description: String {
        "\(self.metadata)"
    }

    let metadata: MySQLQueryMetadata
    let customIDKey: FieldKey?

    func schema(_ schema: String) -> DatabaseOutput {
        self
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        false
    }

    func contains(_ key: FieldKey) -> Bool {
        key == .id || key == self.customIDKey
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        guard self.contains(key) else {
            fatalError("Cannot decode field from last insert row: \(key).")
        }
        if let lastInsertIDInitializable = T.self as? LastInsertIDInitializable.Type {
            return lastInsertIDInitializable.init(lastInsertID: self.metadata.lastInsertID!) as! T
        } else {
            fatalError("Unsupported database generated identifier type: \(T.self).")
        }
    }
}

protocol LastInsertIDInitializable {
    init(lastInsertID: UInt64)
}

extension LastInsertIDInitializable where Self: FixedWidthInteger {
    init(lastInsertID: UInt64) {
        self = numericCast(lastInsertID)
    }
}

extension UInt64: LastInsertIDInitializable { }
extension UInt: LastInsertIDInitializable { }
extension Int: LastInsertIDInitializable { }
extension Int64: LastInsertIDInitializable { }
