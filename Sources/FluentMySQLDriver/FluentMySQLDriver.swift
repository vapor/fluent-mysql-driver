@preconcurrency import AsyncKit
import FluentKit
import MySQLKit
import NIOCore

/// An implementation of `DatabaseDriver` for MySQL .
struct FluentMySQLDriver: DatabaseDriver {
    /// The connection pool set for this driver.
    let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>

    /// A `MySQLDataEncoder` used to translate bound query parameters into `MySQLData` values.
    let encoder: MySQLDataEncoder

    /// A `MySQLDataDecoder` used to translate `MySQLData` values into output values in `SQLRow`s.
    let decoder: MySQLDataDecoder

    /// A logging level used for logging queries.
    let sqlLogLevel: Logger.Level?

    // See `DatabaseDriver.makeDatabase(with:)`.
    func makeDatabase(with context: DatabaseContext) -> any Database {
        FluentMySQLDatabase(
            database: self.pool.pool(for: context.eventLoop).database(logger: context.logger),
            encoder: self.encoder,
            decoder: self.decoder,
            queryLogLevel: self.sqlLogLevel,
            context: context,
            inTransaction: false
        )
    }

    // See `DatabaseDriver.shutdown()`.
    func shutdown() {
        try? self.pool.syncShutdownGracefully()
    }

    func shutdownAsync() async {
        try? await self.pool.shutdownAsync()
    }
}
