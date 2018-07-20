import Fluent
import Service

/// Registers and boots MySQL services.
public final class FluentMySQLProvider: Provider {
    let identifier: DatabaseIdentifier<MySQLDatabase>
    
    /// See Provider.repositoryName
    public static let repositoryName = "fluent-mysql"

    /// Create a new `MySQLProvider`
    ///
    /// - Parameter identifier: the default identifier for the required Database
    public init(default identifier: DatabaseIdentifier<MySQLDatabase> = .mysql) {
        self.identifier = identifier
    }
    
    /// See Provider.register
    public func register(_ services: inout Services) throws {
        try services.register(FluentProvider())
        try services.register(MySQLProvider(default: self.identifier))
    }
    
    /// See Provider.boot
    public func didBoot(_ worker: Container) throws -> EventLoopFuture<Void> {
        return .done(on: worker)
    }
}
