import SQLKit
import AsyncKit

public struct MySQLConfiguration {
    public let address: () throws -> SocketAddress
    public let username: String
    public let password: String
    public let database: String?
    public let tlsConfiguration: TLSConfiguration?
    
    internal var _hostname: String?
    
    public init?(url: URL) {
        guard url.scheme == "mysql" else {
            return nil
        }
        guard let username = url.user else {
            return nil
        }
        guard let password = url.password else {
            return nil
        }
        guard let hostname = url.host else {
            return nil
        }
        guard let port = url.port else {
            return nil
        }
        
        let tlsConfiguration: TLSConfiguration?
        if url.query == "ssl=true" {
            tlsConfiguration = TLSConfiguration.forClient(certificateVerification: .none)
        } else {
            tlsConfiguration = nil
        }
        
        self.init(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: url.path.split(separator: "/").last.flatMap(String.init),
            tlsConfiguration: tlsConfiguration
        )
    }
    
    public init(
        hostname: String,
        port: Int = 3306,
        username: String,
        password: String,
        database: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil
    ) {
        self.address = {
            return try SocketAddress.makeAddressResolvingHost(hostname, port: port)
        }
        self.username = username
        self.database = database
        self.password = password
        self.tlsConfiguration = tlsConfiguration
        self._hostname = hostname
    }
}

public struct MySQLConnectionSource: ConnectionPoolSource {
    public var eventLoop: EventLoop
    public let configuration: MySQLConfiguration
    
    public init(configuration: MySQLConfiguration, on eventLoop: EventLoop) {
        self.configuration = configuration
        self.eventLoop = eventLoop
    }
    
    public func makeConnection() -> EventLoopFuture<MySQLConnection> {
        let address: SocketAddress
        do {
            address = try self.configuration.address()
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return MySQLConnection.connect(
            to: address,
            username: self.configuration.username,
            database: self.configuration.database ?? self.configuration.username,
            password: self.configuration.password,
            tlsConfiguration: self.configuration.tlsConfiguration,
            on: self.eventLoop
        )
    }
}

public struct SQLRaw: SQLExpression {
    public var string: String
    public init(_ string: String) {
        self.string = string
    }
    
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write(self.string)
    }
}

public struct MySQLDialect: SQLDialect {
    public init() {}
    
    public var identifierQuote: SQLExpression {
        return SQLRaw("`")
    }
    
    public var literalStringQuote: SQLExpression {
        return SQLRaw("'")
    }
    
    public mutating func nextBindPlaceholder() -> SQLExpression {
        return SQLRaw("?")
    }
    
    public func literalBoolean(_ value: Bool) -> SQLExpression {
        switch value {
        case false:
            return SQLRaw("0")
        case true:
            return SQLRaw("1")
        }
    }
    
    public var autoIncrementClause: SQLExpression {
        return SQLRaw("AUTO_INCREMENT")
    }
}
