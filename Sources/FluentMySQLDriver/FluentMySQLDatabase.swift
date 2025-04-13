import AsyncKit
import FluentSQL
import MySQLKit
@preconcurrency import MySQLNIO

/// A wrapper for a `MySQLDatabase` which provides `Database`, `SQLDatabase`, and forwarding `MySQLDatabase`
/// conformances.
struct FluentMySQLDatabase: Database, SQLDatabase, MySQLDatabase {
    /// The underlying database connection.
    let database: any MySQLDatabase

    /// A `MySQLDataEncoder` used to translate bound query parameters into `MySQLData` values.
    let encoder: MySQLDataEncoder

    /// A `MySQLDataDecoder` used to translate `MySQLData` values into output values in `SQLRow`s.
    let decoder: MySQLDataDecoder

    /// A logging level used for logging queries.
    let queryLogLevel: Logger.Level?

    /// The `DatabaseContext` associated with this connection.
    let context: DatabaseContext

    /// Whether this is a transaction-specific connection.
    let inTransaction: Bool

    // See `Database.execute(query:onOutput:)`.
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> Void
    ) -> EventLoopFuture<Void> {
        let expression = SQLQueryConverter(delegate: MySQLConverterDelegate()).convert(query)

        guard case .create = query.action, query.customIDKey != .string("") else {
            return self.execute(sql: expression, { onOutput($0.databaseOutput()) })
        }
        // We can't access the query metadata if we route through SQLKit, so we have to duplicate MySQLKit's logic
        // in order to get the last insert ID without running an extra query.
        let (sql, binds) = self.serialize(expression)

        if let queryLogLevel = self.queryLogLevel { self.logger.log(level: queryLogLevel, "\(sql) \(binds)") }
        do {
            return try self.query(
                sql, binds.map { try self.encoder.encode($0) },
                onRow: self.ignoreRow(_:),
                onMetadata: { onOutput(LastInsertRow(lastInsertID: $0.lastInsertID, customIDKey: query.customIDKey)) }
            )
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    /// This is here because it allows for full test coverage; it serves no actual purpose functionally.
    @Sendable /*private*/ func ignoreRow(_: MySQLRow) {}

    /// This is here because it allows for full test coverage; it serves no actual purpose functionally.
    @Sendable /*private*/ func ignoreRow(_: any SQLRow) {}

    // See `Database.execute(schema:)`.
    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let expression = SQLSchemaConverter(delegate: MySQLConverterDelegate()).convert(schema)

        return self.execute(sql: expression, self.ignoreRow(_:))
    }

    // See `Database.execute(enum:)`.
    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        self.eventLoop.makeSucceededVoidFuture()
    }

    // See `Database.transaction(_:)`.
    func transaction<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.inTransaction ? closure(self) : self.eventLoop.makeFutureWithTask { try await self.transaction { try await closure($0).get() } }
    }

    // See `Database.transaction(_:)`.
    func transaction<T>(_ closure: @escaping @Sendable (any Database) async throws -> T) async throws -> T {
        guard !self.inTransaction else {
            return try await closure(self)
        }

        return try await self.withConnection { conn in
            conn.eventLoop.makeFutureWithTask {
                let db = FluentMySQLDatabase(
                    database: conn,
                    encoder: self.encoder,
                    decoder: self.decoder,
                    queryLogLevel: self.queryLogLevel,
                    context: self.context,
                    inTransaction: true
                )

                // N.B.: We cannot route the transaction start/finish queries through the SQLKit interface due to
                // the limitations of MySQLNIO, so we have to use the MySQLNIO interface and log the queries manually.
                if let queryLogLevel = db.queryLogLevel {
                    db.logger.log(level: queryLogLevel, "Executing query", metadata: ["sql": "START TRANSACTION", "binds": []])
                }
                _ = try await conn.simpleQuery("START TRANSACTION").get()
                do {
                    let result = try await closure(db)

                    if let queryLogLevel = db.queryLogLevel {
                        db.logger.log(level: queryLogLevel, "Executing query", metadata: ["sql": "COMMIT", "binds": []])
                    }
                    _ = try await conn.simpleQuery("COMMIT").get()
                    return result
                } catch {
                    if let queryLogLevel = db.queryLogLevel {
                        db.logger.log(level: queryLogLevel, "Executing query", metadata: ["sql": "ROLLBACK", "binds": []])
                    }
                    _ = try? await conn.simpleQuery("ROLLBACK").get()
                    throw error
                }
            }
        }.get()
    }

    // See `Database.withConnection(_:)`.
    func withConnection<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.withConnection {
            closure(
                FluentMySQLDatabase(
                    database: $0,
                    encoder: self.encoder,
                    decoder: self.decoder,
                    queryLogLevel: self.queryLogLevel,
                    context: self.context,
                    inTransaction: self.inTransaction
                ))
        }
    }

    // See `SQLDatabase.dialect`.
    var dialect: any SQLDialect {
        self.sql(encoder: self.encoder, decoder: self.decoder, queryLogLevel: self.queryLogLevel).dialect
    }

    // See `SQLDatabase.execute(sql:_:)`.
    func execute(
        sql query: any SQLExpression,
        _ onRow: @escaping @Sendable (any SQLRow) -> Void
    ) -> EventLoopFuture<Void> {
        self.sql(encoder: self.encoder, decoder: self.decoder, queryLogLevel: self.queryLogLevel).execute(sql: query, onRow)
    }

    // See `SQLDatabase.withSession(_:)`.
    func withSession<R>(_ closure: @escaping @Sendable (any SQLDatabase) async throws -> R) async throws -> R {
        try await self.withConnection { (conn: MySQLConnection) in
            conn.eventLoop.makeFutureWithTask {
                try await closure(conn.sql(encoder: self.encoder, decoder: self.decoder, queryLogLevel: self.queryLogLevel))
            }
        }.get()
    }

    // See `MySQLDatabase.send(_:logger:)`.
    func send(_ command: any MySQLCommand, logger: Logger) -> EventLoopFuture<Void> {
        self.database.send(command, logger: logger)
    }

    // See `MySQLDatabase.withConnection(_:)`.
    func withConnection<T>(_ closure: @escaping (MySQLConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
}

/// A `DatabaseOutput` used to provide last insert IDs from query metadata to the Fluent layer.
/*private*/ struct LastInsertRow: DatabaseOutput {
    // See `CustomStringConvertible.description`.
    var description: String { self.lastInsertID.map { "\($0)" } ?? "nil" }

    /// The last inserted ID as of the creation of this row.
    let lastInsertID: UInt64?

    /// If specified by the original query, an alternative to `FieldKey.id` to be considered valid.
    let customIDKey: FieldKey?

    // See `DatabaseOutput.schema(_:)`.
    func schema(_ schema: String) -> any DatabaseOutput { self }

    // See `DatabaseOutput.decodeNil(_:)`.
    func decodeNil(_ key: FieldKey) throws -> Bool { false }

    // See `DatabaseOutput.contains(_:)`.
    func contains(_ key: FieldKey) -> Bool { key == .id || key == self.customIDKey }

    // See `DatabaseOutput.decode(_:as:)`.
    func decode<T: Decodable>(_ key: FieldKey, as type: T.Type) throws -> T {
        guard let lIDType = T.self as? any LastInsertIDInitializable.Type else {
            throw DecodingError.typeMismatch(T.self, .init(codingPath: [], debugDescription: "\(T.self) is not valid as a last insert ID"))
        }
        guard self.contains(key) else {
            throw DecodingError.keyNotFound(
                SomeCodingKey(stringValue: key.description), .init(codingPath: [], debugDescription: "Metadata doesn't contain key \(key)"))
        }
        guard let lastInsertID = self.lastInsertID else {
            throw DecodingError.valueNotFound(T.self, .init(codingPath: [], debugDescription: "Metadata had no last insert ID"))
        }
        return lIDType.init(lastInsertID: lastInsertID) as! T
    }
}

/// A trivial protocol which identifies types that may be returned by MySQL as "last insert ID" values.
protocol LastInsertIDInitializable {
    /// Create an instance of `Self` from a given unsigned 64-bit integer ID value.
    init(lastInsertID: UInt64)
}

extension LastInsertIDInitializable where Self: FixedWidthInteger {
    /// Default implementation of ``init(lastInsertID:)`` for `FixedWidthInteger`s.
    init(lastInsertID: UInt64) { self = numericCast(lastInsertID) }
}

/// `UInt64` is a valid last inserted ID value type.
extension UInt64: LastInsertIDInitializable {}

/// `UInt` is a valid last inserted ID value type.
extension UInt: LastInsertIDInitializable {}

/// `Int` is a valid last inserted ID value type.
extension Int: LastInsertIDInitializable {}

/// `Int64` is a valid last inserted ID value type.
extension Int64: LastInsertIDInitializable {}
