import AsyncKit
import FluentKit
import MySQLKit
import NIOCore

struct _FluentMySQLDriver: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>
    let encoder: MySQLDataEncoder
    let decoder: MySQLDataDecoder
    
    var eventLoopGroup: EventLoopGroup {
        self.pool.eventLoopGroup
    }
    
    func makeDatabase(with context: DatabaseContext) -> Database {
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
