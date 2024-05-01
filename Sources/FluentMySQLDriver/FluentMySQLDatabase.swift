import FluentSQL
import MySQLKit
import MySQLNIO
import AsyncKit

/// A wrapper for a `MySQLDatabase` which provides `Database`, `SQLDatabase`, and forwarding `MySQLDatabase`
/// conformances.
struct _FluentMySQLDatabase: Database, SQLDatabase, MySQLDatabase {
    /// A trivial wrapper type to work around Sendable warnings due to MySQLNIO not being Sendable-correct.
    struct FakeSendable<T>: @unchecked Sendable { let value: T }
    
    /// The underlying database connection.
    let database: FakeSendable<any MySQLDatabase>
    
    /// A `MySQLDataEncoder` used to translate bound query parameters into `MySQLData` values.
    let encoder: MySQLDataEncoder

    /// A `MySQLDataDecoder` used to translate `MySQLData` values into output values in `SQLRow`s.
    let decoder: MySQLDataDecoder
    
    /// The `DatabaseContext` associated with this connection.
    let context: DatabaseContext
    
    /// Whether this is a transaction-specific connection.
    let inTransaction: Bool
    
    /// Create a ``_FluentMySQLDatabase``.
    init(database: any MySQLDatabase, encoder: MySQLDataEncoder, decoder: MySQLDataDecoder, context: DatabaseContext, inTransaction: Bool) {
        self.database = .init(value: database)
        self.encoder = encoder
        self.decoder = decoder
        self.context = context
        self.inTransaction = inTransaction
    }

    // See `Database.execute(query:onOutput:)`.
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
    
    // See `Database.execute(schema:)`.
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

    // See `Database.execute(enum:)`.
    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededFuture(())
    }

    // See `Database.transaction(_:)`.
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
    
    // See `Database.withConnection(_:)`.
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
    
    // See `SQLDatabase.dialect`.
    var dialect: any SQLDialect {
        self.sql(encoder: self.encoder, decoder: self.decoder).dialect
    }
    
    // See `SQLDatabase.queryLogLevel`.
    var queryLogLevel: Logger.Level? {
        self.sql(encoder: self.encoder, decoder: self.decoder).queryLogLevel
    }
    
    // See `SQLDatabase.execute(sql:_:)`.
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

    // See `MySQLDatabase.send(_:logger:)`.
    func send(_ command: any MySQLCommand, logger: Logger) -> EventLoopFuture<Void> {
        self.database.value.send(command, logger: logger)
    }
    
    // See `MySQLDatabase.withConnection(_:)`.
    func withConnection<T>(_ closure: @escaping (MySQLConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.value.withConnection(closure)
    }
}

/// A `DatabaseOutput` used to provide last insert IDs from query metadata to the Fluent layer.
/*private*/ struct LastInsertRow: DatabaseOutput {
    // See `CustomStringConvertible.description`.
    var description: String {
        "\(self.lastInsertID.map { "\($0)" } ?? "nil")"
    }
    
    /// The last inserted ID as of the creation of this row.
    let lastInsertID: UInt64?
    
    /// If specified by the original query, an alternative to `FieldKey.id` to be considered valid.
    let customIDKey: FieldKey?
    
    // See `DatabaseOutput.schema(_:)`.
    func schema(_ schema: String) -> any DatabaseOutput {
        self
    }

    // See `DatabaseOutput.decodeNil(_:)`.
    func decodeNil(_ key: FieldKey) throws -> Bool {
        false
    }

    // See `DatabaseOutput.contains(_:)`.
    func contains(_ key: FieldKey) -> Bool {
        key == .id || key == self.customIDKey
    }

    // See `DatabaseOutput.decode(_:as:)`.
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

/// A trivial protocol which identifies types that may be returned by MySQL as "last insert ID" values.
protocol LastInsertIDInitializable {
    /// Create an instance of `Self` from a given unsigned 64-bit integer ID value.
    init(lastInsertID: UInt64)
}

extension LastInsertIDInitializable where Self: FixedWidthInteger {
    /// Default implementation of ``init(lastInsertID:)`` for `FixedWidthInteger`s.
    init(lastInsertID: UInt64) {
        self = numericCast(lastInsertID)
    }
}

/// `UInt64` is a valid last inserted ID value type.
extension UInt64: LastInsertIDInitializable { }

/// `UInt` is a valid last inserted ID value type.
extension UInt: LastInsertIDInitializable { }

/// `Int` is a valid last inserted ID value type.
extension Int: LastInsertIDInitializable { }

/// `Int64` is a valid last inserted ID value type.
extension Int64: LastInsertIDInitializable { }
