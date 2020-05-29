extension MySQLRow {
    internal func databaseOutput() -> DatabaseOutput {
        _MySQLDatabaseOutput(row: self, schema: nil)
    }
}

private struct _MySQLDatabaseOutput: DatabaseOutput {
    let row: MySQLRow
    let schema: String?

    var description: String {
        self.row.description
    }

    func contains(_ key: FieldKey) -> Bool {
        self.row.column(self.columnName(key)) != nil
    }

    func nested(_ key: FieldKey) throws -> DatabaseOutput {
        fatalError("Nested fields not yet supported.")
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        if let data = self.row.column((self.columnName(key))) {
            return data.buffer == nil
        } else {
            return true
        }
    }

    func schema(_ schema: String) -> DatabaseOutput {
        _MySQLDatabaseOutput(
            row: self.row,
            schema: schema
        )
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        try self.row.decode(column: self.columnName(key), as: T.self)
    }


    private func columnName(_ key: FieldKey) -> String {
        if let schema = self.schema {
            return "\(schema)_\(key.description)"
        } else {
            return key.description
        }
    }
}
