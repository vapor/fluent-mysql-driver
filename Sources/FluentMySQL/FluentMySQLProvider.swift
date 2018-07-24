import Fluent
import Service

/// Registers and boots MySQL services.
public final class FluentMySQLProvider: Provider {
    /// See Provider.repositoryName
    public static let repositoryName = "fluent-mysql"

    /// Create a new `MySQLProvider`
    public init() {}
    
    /// See Provider.register
    public func register(_ services: inout Services) throws {
        try services.register(FluentProvider())
        try services.register(MySQLProvider())
    }
    
    /// See Provider.boot
    public func didBoot(_ worker: Container) throws -> EventLoopFuture<Void> {
        return .done(on: worker)
    }
}
