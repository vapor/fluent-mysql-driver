import FluentSQL
import MySQLKit
import MySQLNIO
import AsyncKit

struct _FluentMySQLDatabase: Database, SQLDatabase, MySQLDatabase {
    struct FakeSendable<T>: @unchecked Sendable { let value: T }
    let database: FakeSendable<any MySQLDatabase>
    let encoder: MySQLDataEncoder
    let decoder: MySQLDataDecoder
    let context: DatabaseContext
    let inTransaction: Bool

    /// Create a ``_FluentMySQLDatabase``.
    init(database: any MySQLDatabase, encoder: MySQLDataEncoder, decoder: MySQLDataDecoder, context: DatabaseContext, inTransaction: Bool) {
        self.database = .init(value: database)
        self.encoder = encoder
        self.decoder = decoder
        self.context = context
        self.inTransaction = inTransaction
    }
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> ()
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
                    case .create where query.customIDKey != .string(""):
                        let row = LastInsertRow(
                            lastInsertID: metadata.lastInsertID,
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
    
    /// This is here because it allows for full test coverage; it serves no actual purpose functionally.
    /*private*/ func ignoreRow(_: MySQLRow) throws {}
    
    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let expression = SQLSchemaConverter(delegate: MySQLConverterDelegate())
            .convert(schema)
        let (sql, binds) = self.serialize(expression)
        do {
            // Again, this is here purely for the benefit of coverage. It optimizes out as a no-op even in debug.
            try? self.ignoreRow(.init(format: .binary, columnDefinitions: [], values: []))
            
            return try self.query(sql, binds.map { try MySQLDataEncoder().encode($0) }, onRow: self.ignoreRow(_:))
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        guard !self.inTransaction else {
            return closure(self)
        }
        return self.database.value.withConnection { conn in
            conn.simpleQuery("START TRANSACTION").flatMap { _ in
                let db = _FluentMySQLDatabase(
                    database: conn,
                    encoder: self.encoder,
                    decoder: self.decoder,
                    context: self.context,
                    inTransaction: true
                )
                return closure(db).flatMap { result in
                    conn.simpleQuery("COMMIT").and(value: result).map { _, result in
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
    
    func withConnection<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.value.withConnection {
            closure(_FluentMySQLDatabase(
                database: $0,
                encoder: self.encoder,
                decoder: self.decoder,
                context: self.context,
                inTransaction: self.inTransaction
            ))
        }
    }
    var dialect: any SQLDialect {
        self.sql(encoder: self.encoder, decoder: self.decoder).dialect
    }
    
    var queryLogLevel: Logger.Level? {
        self.sql(encoder: self.encoder, decoder: self.decoder).queryLogLevel
    }
    
    func execute(
        sql query: any SQLExpression,
        _ onRow: @escaping @Sendable (any SQLRow) -> ()
    ) -> EventLoopFuture<Void> {
        self.sql(encoder: self.encoder, decoder: self.decoder).execute(sql: query, onRow)
    }
    
    // See `SQLDatabase.withSession(_:)`.
    func withSession<R>(_ closure: @escaping @Sendable (any SQLDatabase) async throws -> R) async throws -> R {
        try await self.withConnection { (conn: MySQLConnection) in
            conn.eventLoop.makeFutureWithTask {
                try await closure(conn.sql(encoder: self.encoder, decoder: self.decoder))
            }
        }.get()
    }

    func send(_ command: any MySQLCommand, logger: Logger) -> EventLoopFuture<Void> {
        self.database.value.send(command, logger: logger)
    }
    
    func withConnection<T>(_ closure: @escaping (MySQLConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.value.withConnection(closure)
    }
}

/*private*/ struct LastInsertRow: DatabaseOutput {
    var description: String {
        "\(self.lastInsertID.map { "\($0)" } ?? "nil")"
    }
    /// The last inserted ID as of the creation of this row.
    let lastInsertID: UInt64?
    
    let customIDKey: FieldKey?
    
    func schema(_ schema: String) -> any DatabaseOutput {
        self
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        false
    }

    func contains(_ key: FieldKey) -> Bool {
        key == .id || key == self.customIDKey
    }

    func decode<T: Decodable>(_ key: FieldKey, as type: T.Type) throws -> T {
        guard let lastInsertIDInitializable = T.self as? any LastInsertIDInitializable.Type else {
            throw DecodingError.typeMismatch(T.self, .init(codingPath: [SomeCodingKey(stringValue: key.description)], debugDescription: "\(T.self) is not valid as a last insert ID"))
        }
        guard self.contains(key) else {
            throw DecodingError.keyNotFound(SomeCodingKey(stringValue: key.description), .init(codingPath: [], debugDescription: "LastInsertRow doesn't contain key \(key)"))
        }
        guard let lastInsertID = self.lastInsertID else {
            throw DecodingError.valueNotFound(T.self, .init(codingPath: [], debugDescription: "LastInsertRow received metadata with no last insert ID"))
        }
        return lastInsertIDInitializable.init(lastInsertID: lastInsertID) as! T
    }
}

/// Retroactive conformance to `Sendable` for `MySQLConnection`, which happens to actually be `Senable`-correct
/// but not annotated as such.
extension MySQLNIO.MySQLConnection: @unchecked Swift.Sendable {}

/// Retroactive conformance to `Sendable` for `MySQLQueryMetadata`, which happens to actually be `Senable`-correct
/// but not annotated as such.
extension MySQLNIO.MySQLQueryMetadata: @unchecked Swift.Sendable {}

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
