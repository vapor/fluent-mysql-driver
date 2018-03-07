extension MySQLDatabase: TransactionSupporting {
    /// Runs a transaction on the MySQL connection
    public static func execute(
        transaction: DatabaseTransaction<MySQLDatabase>,
        on connection: MySQLConnection
    ) -> Future<Void> {
        return connection.simpleQuery("START TRANSACTION").flatMap(to: Void.self) { _ in
            return transaction.run(on: connection).flatMap(to: Void.self) { void in
                return connection.simpleQuery("END TRANSACTION").transform(to: ())
            }
        }.catchFlatMap { error in
            return connection.simpleQuery("ROLLBACK").map(to: Void.self) { _ in
                throw error
            }
        }
    }
}
