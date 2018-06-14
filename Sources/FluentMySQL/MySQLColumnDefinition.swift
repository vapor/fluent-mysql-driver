public typealias MySQLColumnDefinition = MySQLQuery.TypeName

/// A type that can be represented by an appropriate `MySQLColumnDefinition` statically.
public protocol MySQLColumnDefinitionStaticRepresentable {
    /// An appropriate `MySQLColumnDefinition` for this type.
    static var mySQLColumnDefinition: MySQLColumnDefinition { get }
}

extension UUID: MySQLColumnDefinitionStaticRepresentable {
    /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        return .varbinary(16)
    }
}

extension Date: MySQLColumnDefinitionStaticRepresentable {
    /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        return .datetime(6)
    }
}

extension String: MySQLColumnDefinitionStaticRepresentable {
    /// See `MySQLColumnDefinitionStaticRepresentable`.
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        return .varchar(255, nil, nil)
    }
}

extension Decimal: MySQLColumnDefinitionStaticRepresentable {
    /// See `MySQLColumnDefinitionStaticRepresentable`.
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        return .decimal(nil, unsigned: false, zerofill: false)
    }
}

extension FixedWidthInteger {
    /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        switch bitWidth {
        case 8: return .tinyint(nil, unsigned: !isSigned, zerofill: false)
        case 16: return .smallint(nil, unsigned: !isSigned, zerofill: false)
        case 32: return .int(nil, unsigned: !isSigned, zerofill: false)
        case 64: return .bigint(nil, unsigned: !isSigned, zerofill: false)
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
        return .bool
    }
}

extension BinaryFloatingPoint {
    /// See `MySQLColumnDefinitionStaticRepresentable.mySQLColumnDefinition`
    public static var mySQLColumnDefinition: MySQLColumnDefinition {
        let bitWidth = exponentBitCount + significandBitCount + 1
        switch bitWidth {
        case 32: return .float(nil, unsigned: false, zerofill: false)
        case 64: return .double(nil, unsigned: false, zerofill: false)
        default: fatalError("Unsupported bit-width: \(bitWidth)")
        }
    }
}

extension Float: MySQLColumnDefinitionStaticRepresentable { }
extension Double: MySQLColumnDefinitionStaticRepresentable { }
