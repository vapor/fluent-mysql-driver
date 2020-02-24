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

    func contains(_ field: FieldKey) -> Bool {
        return self.row.column(self.column(field)) != nil
    }

    func schema(_ schema: String) -> DatabaseOutput {
        _MySQLDatabaseOutput(
            row: self.row,
            schema: schema
        )
    }

    func decode<T>(
        _ field: FieldKey,
        as type: T.Type
    ) throws -> T where T : Decodable {
        try self.row.decode(column: self.column(field), as: T.self)
    }

    private func column(_ field: FieldKey) -> String {
        if let schema = self.schema {
            return schema + "_" + field.description
        } else {
            return field.description
        }
    }
}
