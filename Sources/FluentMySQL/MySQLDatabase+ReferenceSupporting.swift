import Async

extension MySQLDatabase: ReferenceSupporting {
    /// See `ReferenceSupporting.enableReferences(on:)`
    public static func enableReferences(on connection: MySQLConnection) -> Future<Void> {
        return connection.simpleQuery("SET foreign_key_checks = 1;").transform(to: ())
    }

    /// See `ReferenceSupporting.disableReferences(on:)`
    public static func disableReferences(on connection: MySQLConnection) -> Future<Void> {
        return connection.simpleQuery("SET foreign_key_checks = 0;").transform(to: ())
    }
}
