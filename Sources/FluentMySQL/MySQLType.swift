/// A MySQL type can represent itself statically as a column definition for
/// migrations and convert to / from native MySQL data.
public typealias MySQLType = MySQLColumnDefinitionStaticRepresentable & MySQLDataConvertible
