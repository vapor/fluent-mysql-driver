extension MySQLDatabase: TransactionSupporting {
    public static func transactionExecute<T>(_ transaction: @escaping (MySQLConnection) throws -> Future<T>, on conn: MySQLConnection) -> Future<T> {
        return conn.simpleQuery("START TRANSACTION").flatMap { results in
            return try transaction(conn).flatMap { res in
                return conn.simpleQuery("COMMIT").transform(to: res)
            }.catchFlatMap { error in
                return conn.simpleQuery("ROLLBACK").map { results in
                    throw error
                }
            }
        }
    }
}
