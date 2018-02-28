import MySQL

/// A single column's type
public struct ColumnType {
    /// The column's name
    public private(set) var name: String
    
    /// The textual length of the integer (decimal or character length)
    public private(set) var length: Int? = nil
    
    /// Any other attributes
    public private(set) var attributes = [String]()
    
    /// Serializes the spec
    var keywords: String {
        return attributes.joined(separator: " ")
    }
    
    var lengthName: String {
        guard let length = length else {
            return ""
        }
        
        return "(\(length))"
    }
    
    /// An internal method of creating the column
    init(name: String, length: Int? = nil, attributes: [String] = []) {
        self.name = name
        self.length = length
        self.attributes = attributes
    }
    
    static func attributes(default defaultValue: DefaultValue? = nil, unsigned: Bool = false) -> [String] {
        var attributes: [String] = []
        if let def = defaultValue, let attribute = def.attribute {
            attributes.append(attribute)
        }
        if unsigned {
            attributes.append("UNSIGNED")
        }
        return attributes
    }
    
    /// A `varChar` column type, can be binary
    public static func varChar(length: Int, binary: Bool = false) -> ColumnType {
        var column = ColumnType(name: "VARCHAR", length: length)
        
        if binary {
            column.attributes.append("BINARY")
        }
        
        return column
    }
    
    /// A `varChar` column type, can be binary
    public static func tinyBlob(length: Int) -> ColumnType {
        return ColumnType(name: "TINYBLOB", length: length)
    }
    
    /// A `varChar` column type, can be binary
    public static func blob(length: Int) -> ColumnType {
        return ColumnType(name: "BLOB", length: length)
    }
    
    /// A single signed (TINY) byte with a maximum (decimal) length, if specified
    public static func int8(length: Int? = nil, default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "TINYINT", length: length, attributes: attributes(default: defaultValue))
    }
    
    /// A single unsigned (TINY) byte with a maximum (decimal) length, if specified
    public static func uint8(length: Int? = nil, default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "TINYINT", length: length, attributes: attributes(default: defaultValue, unsigned: true))
    }
    
    /// A single (signed SHORT) Int16 with a maximum (decimal) length, if specified
    public static func int16(length: Int? = nil, default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "SMALLINT", length: length, attributes: attributes(default: defaultValue))
    }
    
    /// A single (unsigned SHORT) UInt16 with a maximum (decimal) length, if specified
    public static func uint16(length: Int? = nil, default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "SMALLINT", length: length, attributes: attributes(default: defaultValue, unsigned: true))
    }
    
    /// A floating point (single precision) 32-bits number
    public static func float(default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "FLOAT", attributes: attributes(default: defaultValue))
    }
    
    /// A floating point (double precision) 64-bits number
    public static func double(default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "DOUBLE", attributes: attributes(default: defaultValue))
    }
    
    /// A MEDIUM integer (24-bits, stored as 32-bits)
    public static func int24(length: Int? = nil, default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "MEDIUMINT", length: length, attributes: attributes(default: defaultValue))
    }
    
    /// An unsigned MEDIUM integer (24-bits, stored as 32-bits)
    public static func uint24(length: Int? = nil, default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "MEDIUMINT", length: length, attributes: attributes(default: defaultValue, unsigned: true))
    }
    
    /// A (signed LONG) 32-bits integer
    public static func int32(length: Int? = nil, default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "INT", length: length, attributes: attributes(default: defaultValue))
    }
    
    /// A (unsigned LONG) 32-bits integer
    public static func uint32(length: Int? = nil, default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "INT", length: length, attributes: attributes(default: defaultValue, unsigned: true))
    }
    
    /// A (signed LONGLONG) 64-bits integer
    public static func int64(length: Int? = nil, default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "BIGINT", length: length, attributes: attributes(default: defaultValue))
    }
    
    /// A (unsigned LONGLONG) 64-bits integer
    public static func uint64(length: Int? = nil, default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "BIGINT", length: length, attributes: attributes(default: defaultValue, unsigned: true))
    }
    
    /// A DATE
    public static func date(default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "DATE", length: nil, attributes: attributes(default: defaultValue))
    }
    
    /// A TEXT
    public static func text(default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "TEXT", length: nil, attributes: attributes(default: defaultValue))
    }
    
    /// A DATETIME
    public static func datetime(default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "DATETIME", length: nil, attributes: attributes(default: defaultValue))
    }
    
    /// A TIME
    public static func time(default defaultValue: DefaultValue? = nil) -> ColumnType {
        return ColumnType(name: "TIME", length: nil, attributes: attributes(default: defaultValue))
    }
}
