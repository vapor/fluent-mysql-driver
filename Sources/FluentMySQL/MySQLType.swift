/// A MySQL type can represent itself statically as a column definition for
/// migrations and convert to / from native MySQL data.
public typealias MySQLType = MySQLColumnDefinitionStaticRepresentable & MySQLDataConvertible

/// A MySQL type that is represented by JSON in the database.
public protocol MySQLJSONType: MySQLType, Codable { }

extension MySQLJSONType {
    /// An appropriate `MySQLColumnDefinition` for this type.
    public static var mySQLColumnDefinition: MySQLColumnDefinition { return .json() }

    /// See `MySQLDataConvertible.convertToMySQLData(format:)`
    public func convertToMySQLData() throws -> MySQLData {
        return try MySQLData(json: self)
    }

    /// See `MySQLDataConvertible.convertFromMySQLData()`
    public static func convertFromMySQLData(_ mysqlData: MySQLData) throws -> Self {
        guard let json = try mysqlData.json(Self.self) else {
            throw MySQLError(identifier: "json", reason: "Could not parse JSON from: \(self)", source: .capture())
        }
        return json
    }
}
