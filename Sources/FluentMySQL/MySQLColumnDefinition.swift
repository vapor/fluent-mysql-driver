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
    public init(name: String, length: Int? = nil, attributes: [String] = []) {
        self.name = name
        self.length = length
        self.attributes = attributes
    }
    
    /// A `varChar` column type, typically used to store strings.
    public static func varChar(length: Int) -> MySQLColumnDefinition {
        return .init(name: "VARCHAR", length: length)
    }
    
    /// A `varChar` column type, can be binary
    public static func tinyBlob(length: Int) -> MySQLColumnDefinition {
        return .init(name: "TINYBLOB", length: length)
    }
    
    /// A `varChar` column type, can be binary
    public static func blob(length: Int) -> MySQLColumnDefinition {
        return .init(name: "BLOB", length: length)
    }

    /// A single signed (TINY) byte with a maximum (decimal) length, if specified
    public static func tinyInt(unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "TINYINT", length: length, attributes: unsigned ? ["UNSIGNED"] : [])
    }

    /// A single (signed SHORT) Int16 with a maximum (decimal) length, if specified
    public static func smallInt(unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "SMALLINT", length: length, attributes: unsigned ? ["UNSIGNED"] : [])
    }

    /// A MEDIUM integer (24-bits, stored as 32-bits)
    public static func mediumInt(unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "MEDIUMINT", length: length, attributes: unsigned ? ["UNSIGNED"] : [])
    }

    /// A LONG 32-bits integer
    public static func int(unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "INT", length: length, attributes: unsigned ? ["UNSIGNED"] : [])
    }

    /// A LONGLONG 64-bits integer
    public static func bigInt(unsigned: Bool = false, length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "BIGINT", length: length, attributes: unsigned ? ["UNSIGNED"] : [])
    }
    
    /// A floating point (single precision) 32-bits number
    public static func float() -> MySQLColumnDefinition {
        return .init(name: "FLOAT")
    }
    
    /// A floating point (double precision) 64-bits number
    public static func double() -> MySQLColumnDefinition {
        return .init(name: "DOUBLE")
    }

    /// A DATE
    public static func date() -> MySQLColumnDefinition {
        return .init(name: "DATE", length: nil)
    }
    
    /// A TEXT
    public static func text() -> MySQLColumnDefinition {
        return .init(name: "TEXT", length: nil)
    }
    
    /// A DATETIME
    public static func datetime() -> MySQLColumnDefinition {
        return .init(name: "DATETIME", length: nil)
    }
    
    /// A TIME
    public static func time() -> MySQLColumnDefinition {
        return .init(name: "TIME", length: nil)
    }
}

extension MySQLColumnDefinition {
    /// A single signed (TINY) byte with a maximum (decimal) length, if specified
    @available(*, renamed: "tinyInt(length:)")
    public static func int8(length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "TINYINT", length: length)
    }

    /// A single unsigned (TINY) byte with a maximum (decimal) length, if specified
    @available(*, renamed: "tinyInt(length:)")
    public static func uint8(length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "TINYINT", length: length, attributes: ["UNSIGNED"])
    }

    /// A single (signed SHORT) Int16 with a maximum (decimal) length, if specified
    @available(*, renamed: "smallInt(length:)")
    public static func int16(length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "SMALLINT", length: length)
    }

    /// A single (unsigned SHORT) UInt16 with a maximum (decimal) length, if specified
    @available(*, renamed: "smallInt(length:)")
    public static func uint16(length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "SMALLINT", length: length, attributes: ["UNSIGNED"])
    }

    /// A MEDIUM integer (24-bits, stored as 32-bits)
    @available(*, renamed: "mediumInt(length:)")
    public static func int24(length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "MEDIUMINT", length: length)
    }

    /// An unsigned MEDIUM integer (24-bits, stored as 32-bits)
    @available(*, renamed: "mediumInt(length:)")
    public static func uint24(length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "MEDIUMINT", length: length, attributes: ["UNSIGNED"])
    }

    /// A (signed LONG) 32-bits integer
    @available(*, renamed: "int(length:)")
    public static func int32(length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "INT", length: length)
    }

    /// A (unsigned LONG) 32-bits integer
    @available(*, renamed: "int(length:)")
    public static func uint32(length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "INT", length: length, attributes: ["UNSIGNED"])
    }

    /// A (signed LONGLONG) 64-bits integer
    @available(*, renamed: "bigint(length:)")
    public static func int64(length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "BIGINT", length: length)
    }

    /// A (unsigned LONGLONG) 64-bits integer
    @available(*, renamed: "bigint(length:)")
    public static func uint64(length: Int? = nil) -> MySQLColumnDefinition {
        return .init(name: "BIGINT", length: length, attributes: ["UNSIGNED"])
    }

}
