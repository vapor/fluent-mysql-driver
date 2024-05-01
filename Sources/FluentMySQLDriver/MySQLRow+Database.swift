import MySQLNIO
import MySQLKit
import FluentKit

extension MySQLRow {
    /// Returns a `DatabaseOutput` for this row.
    /// 
    /// - Parameter decoder: A `MySQLDataDecoder` used to translate `MySQLData` values into output values.
    /// - Returns: A `DatabaseOutput` instance.
    func databaseOutput(decoder: MySQLDataDecoder) -> any DatabaseOutput {
        _MySQLDatabaseOutput(row: self, decoder: decoder, schema: nil)
    }
}

/// A `DatabaseOutput` implementation for `MySQLRow`s.
private struct _MySQLDatabaseOutput: DatabaseOutput {
    /// The underlying row.
    let row: MySQLRow
    
    /// A `MySQLDataDecoder` used to translate `MySQLData` values into output values.
    let decoder: MySQLDataDecoder
    
    /// The most recently set schema value (see `DatabaseOutput.schema(_:)`).
    let schema: String?

    // See `DatabaseOutput.description`.
    var description: String {
        self.row.description
    }

    // See `DatabaseOutput.contains(_:)`.
    func contains(_ key: FieldKey) -> Bool {
        self.row.column(self.columnName(key)) != nil
    }

    // See `DatabaseOutput.decodeNil(_:)`.
    func decodeNil(_ key: FieldKey) throws -> Bool {
        if let data = self.row.column((self.columnName(key))) {
            return data.buffer == nil
        } else {
            return true
        }
    }

    // See `DatabaseOutput.schema(_:)`.
    func schema(_ schema: String) -> any DatabaseOutput {
        _MySQLDatabaseOutput(
            row: self.row,
            decoder: self.decoder,
            schema: schema
        )
    }

    // See `DatabaseOutput.decode(_:as:)`.
    func decode<T: Decodable>(_ key: FieldKey, as type: T.Type) throws -> T {
        try self.row
            .sql(decoder: self.decoder)
            .decode(column: self.columnName(key), as: T.self)
    }

    /// Translates a given `FieldKey` into a column name, accounting for the current schema, if any.
    private func columnName(_ key: FieldKey) -> String {
        if let schema = self.schema {
            return "\(schema)_\(key.description)"
        } else {
            return key.description
        }
    }
}
