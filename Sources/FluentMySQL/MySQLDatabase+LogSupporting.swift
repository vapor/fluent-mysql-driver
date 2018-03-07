extension MySQLDatabase: LogSupporting {
    /// See `LogSupporting.enableLogging(using:)`
    public func enableLogging(using logger: DatabaseLogger) {
        self.logger = logger
    }
}
