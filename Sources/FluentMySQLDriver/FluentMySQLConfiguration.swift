import AsyncKit
import struct NIO.TimeAmount
import FluentKit
import MySQLKit

extension DatabaseConfigurationFactory {
    /// Create a database configuration factory for connecting to a server through a UNIX domain socket.
    ///
    /// - Parameters:
    ///   - unixDomainSocketPath: The path to the UNIX domain socket to connect through.
    ///   - username: The username to use for the connection.
    ///   - password: The password (empty string for none) to use for the connection.
    ///   - database: The default database for the connection, if any.
    ///   - maxConnectionsPerEventLoop: The maximum number of database connections to add to each event loop's pool.
    ///   - connectionPoolTimeout: The timeout for queries on the connection pool's wait list.
    ///   - encoder: A `MySQLDataEncoder` used to translate bound query parameters into `MySQLData` values.
    ///   - decoder: A `MySQLDataDecoder` used to translate `MySQLData` values into output values in `SQLRow`s.
    /// - Returns: An appropriate configuration factory.
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
    
    /// Create a database configuration factory from an appropriately formatted URL string.
    ///
    /// - Parameters:
    ///   - url: A URL-formatted MySQL connection string. See `MySQLConfiguration` in MySQLKit for details of
    ///     accepted URL formats.
    ///   - maxConnectionsPerEventLoop: The maximum number of database connections to add to each event loop's pool.
    ///   - connectionPoolTimeout: The timeout for queries on the connection pool's wait list.
    ///   - encoder: A `MySQLDataEncoder` used to translate bound query parameters into `MySQLData` values.
    ///   - decoder: A `MySQLDataDecoder` used to translate `MySQLData` values into output values in `SQLRow`s.
    /// - Returns: An appropriate configuration factory.
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

    /// Create a database configuration factory from an appropriately formatted URL string.
    ///
    /// - Parameters:
    ///   - url: A `URL` containing MySQL connection parameters. See `MySQLConfiguration` in MySQLKit for details of
    ///     accepted URL formats.
    ///   - maxConnectionsPerEventLoop: The maximum number of database connections to add to each event loop's pool.
    ///   - connectionPoolTimeout: The timeout for queries on the connection pool's wait list.
    ///   - encoder: A `MySQLDataEncoder` used to translate bound query parameters into `MySQLData` values.
    ///   - decoder: A `MySQLDataDecoder` used to translate `MySQLData` values into output values in `SQLRow`s.
    /// - Returns: An appropriate configuration factory.
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

    /// Create a database configuration factory for connecting to a server with a hostname and optional port.
    ///
    /// - Parameters:
    ///   - hostname: The hostname to connect to.
    ///   - port: A TCP port number to connect on. Defaults to the IANA-assigned MySQL port number (3306).
    ///   - username: The username to use for the connection.
    ///   - password: The password (empty string for none) to use for the connection.
    ///   - database: The default database for the connection, if any.
    ///   - tlsConfiguration: An optional `TLSConfiguration` specifying encryption for the connection.
    ///   - maxConnectionsPerEventLoop: The maximum number of database connections to add to each event loop's pool.
    ///   - connectionPoolTimeout: The timeout for queries on the connection pool's wait list.
    ///   - encoder: A `MySQLDataEncoder` used to translate bound query parameters into `MySQLData` values.
    ///   - decoder: A `MySQLDataDecoder` used to translate `MySQLData` values into output values in `SQLRow`s.
    /// - Returns: An appropriate configuration factory.
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
        .mysql(
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

    /// Create a database configuration factory for connecting to a server with a given `MySQLConfiguration`.
    ///
    /// - Parameters:
    ///   - configuration: A connection configuration.
    ///   - maxConnectionsPerEventLoop: The maximum number of database connections to add to each event loop's pool.
    ///   - connectionPoolTimeout: The timeout for queries on the connection pool's wait list.
    ///   - encoder: A `MySQLDataEncoder` used to translate bound query parameters into `MySQLData` values.
    ///   - decoder: A `MySQLDataDecoder` used to translate `MySQLData` values into output values in `SQLRow`s.
    /// - Returns: An appropriate configuration factory.
    public static func mysql(
        configuration: MySQLConfiguration,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: NIO.TimeAmount = .seconds(10),
        encoder: MySQLDataEncoder = .init(),
        decoder: MySQLDataDecoder = .init()
    ) -> Self {
        Self {
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

/// An implementation of `DatabaseConfiguration` for MySQL configurations.
struct FluentMySQLConfiguration: DatabaseConfiguration {
    /// The underlying `MySQLConfiguration`.
    let configuration: MySQLConfiguration
    
    /// The maximum number of database connections to add to each event loop's pool.
    let maxConnectionsPerEventLoop: Int
    
    /// The timeout for queries on the connection pool's wait list.
    let connectionPoolTimeout: TimeAmount

    /// A `MySQLDataEncoder` used to translate bound query parameters into `MySQLData` values.
    let encoder: MySQLDataEncoder

    /// A `MySQLDataDecoder` used to translate `MySQLData` values into output values in `SQLRow`s.
    let decoder: MySQLDataDecoder
    
    // See `DatabaseConfiguration.middleware`.
    var middleware: [any AnyModelMiddleware]
    
    // See `DatabaseConfiguration.makeDriver(for:)`.
    func makeDriver(for databases: Databases) -> any DatabaseDriver {
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
