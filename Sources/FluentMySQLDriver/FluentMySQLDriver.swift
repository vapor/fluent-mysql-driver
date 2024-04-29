@preconcurrency import AsyncKit
import FluentKit
import MySQLKit
import NIOCore

struct _FluentMySQLDriver: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>
    let encoder: MySQLDataEncoder
    let decoder: MySQLDataDecoder
    
    func makeDatabase(with context: DatabaseContext) -> any Database {
        _FluentMySQLDatabase(
            database: self.pool.pool(for: context.eventLoop).database(logger: context.logger),
            encoder: self.encoder,
            decoder: self.decoder,
            context: context,
            inTransaction: false
        )
    }
    
    func shutdown() {
        self.pool.shutdown()
    }
}
