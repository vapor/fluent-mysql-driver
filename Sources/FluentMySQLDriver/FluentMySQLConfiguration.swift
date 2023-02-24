import AsyncKit
import struct NIO.TimeAmount
import FluentKit
import MySQLKit

extension DatabaseConfigurationFactory {
    public static func mysql(
        unixDomainSocketPath: String,
        username: String,
        password: String,
        database: String? = nil,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10),
        encoder: MySQLDataEncoder = .init(),
        decoder: MySQLDataDecoder = .init()
    ) throws -> Self {
        let configuration = MySQLConfiguration(
            unixDomainSocketPath: unixDomainSocketPath,
            username: username,
            password: password,
            database: database
        )
        return .mysql(
            configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            encoder: encoder,
            decoder: decoder
        )
    }
    public static func mysql(
        url urlString: String,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10),
        encoder: MySQLDataEncoder = .init(),
        decoder: MySQLDataDecoder = .init()
    ) throws -> Self {
        guard let url = URL(string: urlString) else {
            throw FluentMySQLError.invalidURL(urlString)
        }
        return try self.mysql(
            url: url,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            encoder: encoder,
            decoder: decoder
        )
    }

    public static func mysql(
        url: URL,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10),
        encoder: MySQLDataEncoder = .init(),
        decoder: MySQLDataDecoder = .init()
    ) throws -> Self {
        guard let configuration = MySQLConfiguration(url: url) else {
            throw FluentMySQLError.invalidURL(url.absoluteString)
        }
        return .mysql(
            configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            encoder: encoder,
            decoder: decoder
        )
    }

    public static func mysql(
        hostname: String,
        port: Int = 3306,
        username: String,
        password: String,
        database: String? = nil,
        tlsConfiguration: TLSConfiguration? = .makeClientConfiguration(),
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10),
        encoder: MySQLDataEncoder = .init(),
        decoder: MySQLDataDecoder = .init()
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
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            encoder: encoder,
            decoder: decoder
        )
    }

    public static func mysql(
        configuration: MySQLConfiguration,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10),
        encoder: MySQLDataEncoder = .init(),
        decoder: MySQLDataDecoder = .init()
    ) -> Self {
        return Self {
            FluentMySQLConfiguration(
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                connectionPoolTimeout: connectionPoolTimeout,
                encoder: encoder,
                decoder: decoder,
                middleware: []
            )
        }
    }
}

struct FluentMySQLConfiguration: DatabaseConfiguration {
    let configuration: MySQLConfiguration
    let maxConnectionsPerEventLoop: Int
    let connectionPoolTimeout: TimeAmount
    let encoder: MySQLDataEncoder
    let decoder: MySQLDataDecoder
    var middleware: [AnyModelMiddleware]

    func makeDriver(for databases: Databases) -> DatabaseDriver {
        let db = MySQLConnectionSource(
            configuration: self.configuration
        )
        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: self.maxConnectionsPerEventLoop,
            requestTimeout: self.connectionPoolTimeout,
            on: databases.eventLoopGroup
        )
        return _FluentMySQLDriver(
            pool: pool,
            encoder: self.encoder,
            decoder: self.decoder
        )
    }
}
