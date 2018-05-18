import Foundation
import MySQL

/// A single column's type
public struct MySQLColumnDefinition {
    /// The column's name
    public var name: String
    
    /// The column's maximum data length. This will be appended after the column name wrapped in parentheses.
    public var length: Int? = nil
    
    /// Any other attributes such as `NOT NULL` or `UNSIGNED`.
    public var attributes: [String]
    
    /// An internal method of creating the column
    public init(name: String, length: Int? = nil) {
        self.name = name
        self.length = length
        self.attributes = ["NOT NULL"]
    }
    
    /// A `varChar` column type, typically used to store strings.
    public static func varChar(length: Int) -> MySQLColumnDefinition {
        return .init(name: "VARCHAR", length: length)
    }

    /// A `varChar` column type, typically used to store strings.
    public static func varBinary(length: Int) -> MySQLColumnDefinition {
        return .init(name: "VARBINARY", length: length)
    }
    
    /// A `varChar` column type, can be binary
    public static func tinyBlob(length: Int) -> MySQLColumnDefinition {
        return .init(name: "TINYBLOB", length: length)
    }
    
    /// A `varChar` column type, can be binary
    public static func blob(length: Int) -> MySQLColumnDefinition {
        return .init(name: "BLOB", length: length)
    }

    /// A BOOLEAN type.
    public static func bool() -> MySQLColumnDefinition {
        return .init(name: "BOOL")
    }

    /// A single signed (TINY) byte with a maximum (decimal) length, if specified
    public static func tinyInt(unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        return _int("TINYINT", unsigned: unsigned, length: length)
    }

    /// A single (signed SHORT) Int16 with a maximum (decimal) length, if specified
    public static func smallInt(unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        return _int("SMALLINT", unsigned: unsigned, length: length)
    }

    /// A MEDIUM integer (24-bits, stored as 32-bits)
    public static func mediumInt(unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        return _int("MEDIUMINT", unsigned: unsigned, length: length)
    }

    /// A LONG 32-bits integer
    public static func int(unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        return _int("INT", unsigned: unsigned, length: length)
    }

    /// A LONGLONG 64-bits integer
    public static func bigInt(unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        return _int("BIGINT", unsigned: unsigned, length: length)
    }

    /// Private, generic int
    private static func _int(_ type: String, unsigned: Bool, length: Int?) -> MySQLColumnDefinition {
        var col = MySQLColumnDefinition(name: type, length: length)
        if unsigned {
            col.attributes.append("UNSIGNED")
        }
        return col
    }
    
    /// A floating point (single precision) 32-bits number
    public static func float() -> MySQLColumnDefinition {
        return .init(name: "FLOAT")
    }
    
    /// A floating point (double precision) 64-bits number
    public static func double() -> MySQLColumnDefinition {
        return .init(name: "DOUBLE")
    }

    /// A `DATE` column.
    public static func date() -> MySQLColumnDefinition {
        return .init(name: "DATE", length: nil)
    }
    
    /// A `TEXT` column.
    public static func text() -> MySQLColumnDefinition {
        return .init(name: "TEXT", length: nil)
    }
    
    /// A `DATETIME` column.
    public static func datetime() -> MySQLColumnDefinition {
        return .init(name: "DATETIME(6)", length: nil)
    }
    
    /// A `TIME` column.
    public static func time() -> MySQLColumnDefinition {
        return .init(name: "TIME(6)", length: nil)
    }

    /// A `BINARY` column used to store fixed-size byte arrays.
    public static func binary(length: Int) -> MySQLColumnDefinition {
        return .init(name: "BINARY", length: length)
    }

    /// A `JSON` column used to store variable length JSON-encoded data.
    public static func json() -> MySQLColumnDefinition {
        return .init(name: "JSON")
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
        let wrapped = representable.mySQLColumnDefinition
        var col = MySQLColumnDefinition(name: wrapped.name, length: wrapped.length)
        col.attributes = col.attributes.filter { $0 != "NOT NULL" }
        return col
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
