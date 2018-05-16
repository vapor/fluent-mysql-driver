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

extension MySQLText: MySQLColumnDefinitionStaticRepresentable {
    /// See `MySQLColumnDefinitionStaticRepresentable`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        return .text()
    }
}

// MARK: Enum
/// This type-alias makes it easy to declare nested enum types for your `MySQLModel`.
///
///     enum PetType: Int, MySQLEnumType {
///         case cat, dog
///     }
///
/// `MySQLEnumType` can be used easily with any enum that has a `MySQLType` conforming `RawValue`.
///
/// You will need to implement custom `ReflectionDecodable` conformance for enums that have non-standard integer
/// values or enums whose `RawValue` is not an integer.
///
///     enum FavoriteTreat: String, MySQLEnumType {
///         case bone = "b"
///         case tuna = "t"
///         static func reflectDecoded() -> (FavoriteTreat, FavoriteTreat) {
///             return (.bone, .tuna)
///         }
///     }
///
public protocol MySQLEnumType: MySQLType, ReflectionDecodable, Codable, RawRepresentable where Self.RawValue: MySQLDataConvertible { }

/// Provides a default `MySQLColumnDefinitionStaticRepresentable` implementation where the type is also
/// `RawRepresentable` by a `MySQLColumnDefinitionStaticRepresentable` type.
extension MySQLColumnDefinitionStaticRepresentable where Self: RawRepresentable, Self.RawValue: MySQLColumnDefinitionStaticRepresentable
{
    public static var mySQLColumnDefinition: MySQLColumnDefinition { return RawValue.mySQLColumnDefinition }
}

/// Provides a default `MySQLDataConvertible` implementation where the type is also
/// `RawRepresentable` by a `MySQLDataConvertible` type.
extension MySQLDataConvertible where Self: RawRepresentable, Self.RawValue: MySQLDataConvertible
{
    /// See `MySQLDataConvertible.convertToMySQLData()`
    public func convertToMySQLData() throws -> MySQLData {
        return try rawValue.convertToMySQLData()
    }

    /// See `MySQLDataConvertible.convertFromMySQLData(_:)`
    public static func convertFromMySQLData(_ data: MySQLData) throws -> Self {
        guard let e = try self.init(rawValue: .convertFromMySQLData(data)) else {
            throw MySQLError(
                identifier: "rawValue",
                reason: "Could not create `\(Self.self)` from: \(data)",
                source: .capture()
            )
        }
        return e
    }
}
