extension QueryBuilder where Database == MySQLDatabase {
    public func queryMetadata() -> Future<MySQLConnection.Metadata> {
        return connection.map { conn in
            guard let metadata = conn.lastMetadata else {
                throw MySQLError(identifier: "metadata", reason: "No query metadata.")
            }
            return metadata
        }
    }
}
