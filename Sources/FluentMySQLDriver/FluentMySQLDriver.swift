import AsyncKit

struct _FluentMySQLDriver: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>
    
    var eventLoopGroup: EventLoopGroup {
        self.pool.eventLoopGroup
    }
    
    func makeDatabase(with context: DatabaseContext) -> Database {
        _FluentMySQLDatabase(
            database: self.pool.pool(for: context.eventLoop).database(logger: context.logger),
            context: context,
            inTransaction: false
        )
    }
    
    func shutdown() {
        self.pool.shutdown()
    }
}
