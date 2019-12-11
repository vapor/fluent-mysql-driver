import AsyncKit

extension DatabaseDriverFactory {
    public static func mysql(
        url: URL,
        maxConnectionsPerEventLoop: Int = 1
    ) throws -> DatabaseDriverFactory {
        guard let configuration = MySQLConfiguration(url: url) else {
            throw FluentMySQLError.invalidURL(url)
        }
        return .mysql(
            configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop
        )
    }
    
    public static func mysql(
        hostname: String,
        port: Int = 3306,
        username: String,
        password: String,
        database: String? = nil,
        tlsConfiguration: TLSConfiguration? = .forClient(),
        maxConnectionsPerEventLoop: Int = 1
    ) -> DatabaseDriverFactory {
        return .mysql(
            configuration: .init(
                hostname: hostname,
                port: port,
                username: username,
                password: password,
                database: database,
                tlsConfiguration: tlsConfiguration
            ),
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop
        )
    }
    
    public static func mysql(
        configuration: MySQLConfiguration,
        maxConnectionsPerEventLoop: Int = 1
    ) -> DatabaseDriverFactory {
        return DatabaseDriverFactory { databases in
            let db = MySQLConnectionSource(
                configuration: configuration
            )
            let pool = EventLoopGroupConnectionPool(
                source: db,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                on: databases.eventLoopGroup
            )
            return _FluentMySQLDriver(pool: pool)
        }
    }
}

enum FluentMySQLError: Error {
    case invalidURL(URL)
}

struct _FluentMySQLDriver: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<MySQLConnectionSource>
    
    var eventLoopGroup: EventLoopGroup {
        self.pool.eventLoopGroup
    }
    
    func makeDatabase(with context: DatabaseContext) -> Database {
        _FluentMySQLDatabase(
            database: self.pool.pool(for: context.eventLoop).database(logger: context.logger),
            context: context
        )
    }
    
    func shutdown() {
        self.pool.shutdown()
    }
}
