/// A MySQL type can represent itself statically as a column definition for
/// migrations and convert to / from native MySQL data.
public typealias MySQLType = MySQLDataTypeStaticRepresentable & MySQLDataConvertible

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
extension MySQLDataTypeStaticRepresentable where Self: RawRepresentable, Self.RawValue: MySQLDataTypeStaticRepresentable
{
    public static var mysqlDataType: MySQLDataType {
        return RawValue.mysqlDataType
    }
}

/// Provides a default `MySQLDataConvertible` implementation where the type is also
/// `RawRepresentable` by a `MySQLDataConvertible` type.
extension MySQLDataConvertible where Self: RawRepresentable, Self.RawValue: MySQLDataConvertible
{
    /// See `MySQLDataConvertible.convertToMySQLData()`
    public func convertToMySQLData() -> MySQLData {
        return rawValue.convertToMySQLData()
    }

    /// See `MySQLDataConvertible.convertFromMySQLData(_:)`
    public static func convertFromMySQLData(_ data: MySQLData) throws -> Self {
        guard let extractedCase = try self.init(rawValue: .convertFromMySQLData(data)) else {
            throw MySQLError(identifier: "rawValue", reason: "Could not create `\(Self.self)` from: \(data)")
        }
        return extractedCase
    }
}
