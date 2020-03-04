import AsyncKit

extension DatabaseConfigurationFactory {
    public static func mysql(
        unixDomainSocketPath: String,
        username: String,
        password: String,
        database: String? = nil,
        maxConnectionsPerEventLoop: Int = 1
    ) throws -> Self {
        let configuration = MySQLConfiguration(
            unixDomainSocketPath: unixDomainSocketPath,
            username: username,
            password: password,
            database: database
        )
        return .mysql(
            configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop
        )
    }
    public static func mysql(
        url urlString: String,
        maxConnectionsPerEventLoop: Int = 1
    ) throws -> Self {
        guard let url = URL(string: urlString) else {
            throw FluentMySQLError.invalidURL(urlString)
        }
        return try self.mysql(url: url, maxConnectionsPerEventLoop: maxConnectionsPerEventLoop)
    }

    public static func mysql(
        url: URL,
        maxConnectionsPerEventLoop: Int = 1
    ) throws -> Self {
        guard let configuration = MySQLConfiguration(url: url) else {
            throw FluentMySQLError.invalidURL(url.absoluteString)
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
    ) -> Self {
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
    ) -> Self {
        return Self {
            FluentMySQLConfiguration(
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                middleware: []
            )
        }
    }
}

struct FluentMySQLConfiguration: DatabaseConfiguration {
    let configuration: MySQLConfiguration
    let maxConnectionsPerEventLoop: Int
    var middleware: [AnyModelMiddleware]

    func makeDriver(for databases: Databases) -> DatabaseDriver {
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
