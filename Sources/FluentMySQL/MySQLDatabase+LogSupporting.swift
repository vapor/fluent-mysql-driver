extension MySQLDatabase: LogSupporting {
    /// See `LogSupporting`.
    public static func enableLogging(_ logger: DatabaseLogger, on conn: MySQLConnection) {
        conn.logger = logger
    }
}
