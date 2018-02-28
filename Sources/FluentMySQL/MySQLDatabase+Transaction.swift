import Async
import MySQL

extension MySQLDatabase: TransactionSupporting {
    /// Runs a transaction on the MySQL connection
    public static func execute(
        transaction: DatabaseTransaction<MySQLDatabase>,
        on connection: MySQLConnection
    ) -> Future<Void> {
        let promise = Promise<Void>()

        connection.administrativeQuery("START TRANSACTION").flatMap(to: Void.self) {
            return transaction.run(on: connection)
        }.addAwaiter { result in
            if let error = result.error {
                connection.administrativeQuery("ROLLBACK").do {
                    // still fail even though rollback succeeded
                    promise.fail(error)
                }.catch { error in
                    promise.fail(error)
                }
            } else {
                promise.complete()
            }
        }

        return promise.future
    }
}
