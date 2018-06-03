public typealias MySQLColumnDefinition = MySQLDataType

/// A single column's type
public struct MySQLDataType {
    /// A `varChar` column type, typically used to store strings.
    public static func varChar(length: Int = 255) -> MySQLDataType {
        return make("VARCHAR", length: length)
    }

    /// A `varChar` column type, typically used to store strings.
    public static func varBinary(length: Int) -> MySQLDataType {
        return make("VARBINARY", length: length)
    }

    /// A `BINARY` column used to store fixed-size byte arrays.
    public static func binary(length: Int) -> MySQLDataType {
        return make("BINARY", length: length)
    }
    
    /// A `varChar` column type, can be binary
    public static func tinyBlob(length: Int) -> MySQLDataType {
        return make("TINYBLOB", length: length)
    }
    
    /// A `varChar` column type, can be binary
    public static func blob(length: Int) -> MySQLDataType {
        return make("BLOB", length: length)
    }

    /// A BOOLEAN type.
    public static func bool() -> MySQLDataType {
        return make("BOOL")
    }

    /// A floating point (single precision) 32-bits number
    public static func float() -> MySQLDataType {
        return make("FLOAT")
    }
    
    /// A floating point (double precision) 64-bits number
    public static func double() -> MySQLDataType {
        return make("DOUBLE")
    }

    /// A `DATE` column.
    public static func date() -> MySQLDataType {
        return make("DATE")
    }
    
    /// A `TEXT` column.
    public static func text() -> MySQLDataType {
        return make("TEXT")
    }
    
    /// A `DATETIME` column.
    public static func datetime() -> MySQLDataType {
        return make("DATETIME", length: 6)
    }
    
    /// A `TIME` column.
    public static func time() -> MySQLDataType {
        return make("TIME", length: 6)
    }

    /// A `JSON` column used to store variable length JSON-encoded data.
    public static func json() -> MySQLDataType {
        return make("JSON")
    }

    /// A single signed (TINY) byte with a maximum (decimal) length, if specified
    public static func tinyInt(unsigned: Bool = false, length: Int? = nil) -> MySQLDataType {
        return make("TINYINT", unsigned: unsigned, length: length)
    }

    /// A single (signed SHORT) Int16 with a maximum (decimal) length, if specified
    public static func smallInt(unsigned: Bool = false, length: Int? = nil) -> MySQLDataType {
        return make("SMALLINT", unsigned: unsigned, length: length)
    }

    /// A MEDIUM integer (24-bits, stored as 32-bits)
    public static func mediumInt(unsigned: Bool = false, length: Int? = nil) -> MySQLDataType {
        return make("MEDIUMINT", unsigned: unsigned, length: length)
    }

    /// A LONG 32-bits integer
    public static func int(unsigned: Bool = false, length: Int? = nil) -> MySQLDataType {
        return make("INT", unsigned: unsigned, length: length)
    }

    /// A LONGLONG 64-bits integer
    public static func bigInt(unsigned: Bool = false, length: Int? = nil) -> MySQLDataType {
        return make("BIGINT", unsigned: unsigned, length: length)
    }
    
    public var name: String
    public var parameters: [String]
    public var attributes: [String]

    /// An internal method of creating the column
    public init(name: String, parameters: [String] = [], attributes: [String] = ["NOT NULL"]) {
        self.name = name
        self.parameters = parameters
        self.attributes = attributes
    }

    // MARK: Private

    private static func make(_ type: String, unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        var type: MySQLDataType = .init(name: type)
        if unsigned {
            type.attributes.append("UNSIGNED")
        }
        if let length = length {
            type.parameters.append(length.description)
        }
        return type
    }
}

/// A type that can be represented by an appropriate `MySQLColumnDefinition` statically.
public protocol MySQLColumnDefinitionStaticRepresentable {
    /// An appropriate `MySQLColumnDefinition` for this type.
    static var mySQLColumnDefinition: MySQLColumnDefinition { get }
}

extension UUID: MySQLColumnDefinitionStaticRepresentable {
    /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        return .varBinary(length: 16)
    }
}

extension Date: MySQLColumnDefinitionStaticRepresentable {
    /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        return .datetime()
    }
}

extension String: MySQLColumnDefinitionStaticRepresentable {
    /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        return .varChar(length: 255)
    }
}

extension Optional: MySQLColumnDefinitionStaticRepresentable {
    /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        guard let representable = Wrapped.self as? MySQLColumnDefinitionStaticRepresentable.Type else {
            fatalError("No MySQL column type known for \(Wrapped.Type.self).")
        }

        // remove NOT NULL since this is optional
        var type = representable.mySQLColumnDefinition
        type.attributes = type.attributes.filter { $0 != "NOT NULL" }
        return type
    }
}

extension FixedWidthInteger {
    /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        switch bitWidth {
        case 8: return .tinyInt(unsigned: !isSigned)
        case 16: return .smallInt(unsigned: !isSigned)
        case 32: return .int(unsigned: !isSigned)
        case 64: return .bigInt(unsigned: !isSigned)
        default: fatalError("Unsupported bit-width: \(bitWidth)")
        }
    }
}

extension Int8: MySQLColumnDefinitionStaticRepresentable { }
extension Int16: MySQLColumnDefinitionStaticRepresentable { }
extension Int32: MySQLColumnDefinitionStaticRepresentable { }
extension Int64: MySQLColumnDefinitionStaticRepresentable { }
extension Int: MySQLColumnDefinitionStaticRepresentable { }
extension UInt8: MySQLColumnDefinitionStaticRepresentable { }
extension UInt16: MySQLColumnDefinitionStaticRepresentable { }
extension UInt32: MySQLColumnDefinitionStaticRepresentable { }
extension UInt64: MySQLColumnDefinitionStaticRepresentable { }
extension UInt: MySQLColumnDefinitionStaticRepresentable { }

extension Bool: MySQLColumnDefinitionStaticRepresentable {
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
        return .bool()
    }
}

extension BinaryFloatingPoint {
    /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        let bitWidth = exponentBitCount + significandBitCount + 1
        switch bitWidth {
        case 32: return .float()
        case 64: return .double()
        default: fatalError("Unsupported bit-width: \(bitWidth)")
        }
    }
}

extension Float: MySQLColumnDefinitionStaticRepresentable { }
extension Double: MySQLColumnDefinitionStaticRepresentable { }
