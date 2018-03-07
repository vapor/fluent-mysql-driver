import Async

extension MySQLDatabase: ReferenceSupporting {
    /// See `ReferenceSupporting.enableReferences(on:)`
    public static func enableReferences(on connection: MySQLConnection) -> Future<Void> {
        // enabled by default
        return .done(on: connection)
    }

    /// See `ReferenceSupporting.disableReferences(on:)`
    public static func disableReferences(on connection: MySQLConnection) -> Future<Void> {
        return Future.map(on: connection) {
            throw MySQLError(identifier: "disableReferences", reason: "MySQL does not support disabling foreign key checks.", source: .capture())
        }
    }
}
