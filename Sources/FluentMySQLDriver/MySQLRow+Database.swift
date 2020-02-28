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

    func contains(_ path: [FieldKey]) -> Bool {
        return self.row.column(self.columnName(path)) != nil
    }

    func schema(_ schema: String) -> DatabaseOutput {
        _MySQLDatabaseOutput(
            row: self.row,
            schema: schema
        )
    }

    func decode<T>(
        _ path: [FieldKey],
        as type: T.Type
    ) throws -> T where T : Decodable {
        try self.row.decode(column: self.columnName(path), as: T.self)
    }


    private func columnName(_ path: [FieldKey]) -> String {
        let field = path.map { $0.description }.joined(separator: "_")
        if let schema = self.schema {
            return "\(schema)_\(field)"
        } else {
            return field
        }

    }
}
