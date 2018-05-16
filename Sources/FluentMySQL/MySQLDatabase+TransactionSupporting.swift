extension MySQLDatabase: TransactionSupporting {
    /// Runs a transaction on the MySQL connection
    public static func execute<R>(
        transaction: DatabaseTransaction<MySQLDatabase, R>,
        on connection: MySQLConnection
    ) -> Future<R> {
        return connection.simpleQuery("START TRANSACTION").flatMap(to: R.self) { _ in
            return transaction.run(on: connection).flatMap(to: R.self) { result in
                return connection.simpleQuery("COMMIT").transform(to: result)
            }
        }.catchFlatMap { error in
            return connection.simpleQuery("ROLLBACK").map(to: R.self) { _ in
                throw error
            }
        }
    }
}
