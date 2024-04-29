import MySQLNIO
import MySQLKit
import FluentKit

extension MySQLRow {
    func databaseOutput(decoder: MySQLDataDecoder) -> any DatabaseOutput {
        _MySQLDatabaseOutput(row: self, decoder: decoder, schema: nil)
    }
}

private struct _MySQLDatabaseOutput: DatabaseOutput {
    let row: MySQLRow
    let decoder: MySQLDataDecoder
    let schema: String?

    var description: String {
        self.row.description
    }

    func contains(_ key: FieldKey) -> Bool {
        self.row.column(self.columnName(key)) != nil
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        if let data = self.row.column((self.columnName(key))) {
            return data.buffer == nil
        } else {
            return true
        }
    }

    func schema(_ schema: String) -> any DatabaseOutput {
        _MySQLDatabaseOutput(
            row: self.row,
            decoder: self.decoder,
            schema: schema
        )
    }

    func decode<T: Decodable>(_ key: FieldKey, as type: T.Type) throws -> T {
        try self.row
            .sql(decoder: self.decoder)
            .decode(column: self.columnName(key), as: T.self)
    }


    private func columnName(_ key: FieldKey) -> String {
        if let schema = self.schema {
            return "\(schema)_\(key.description)"
        } else {
            return key.description
        }
    }
}
