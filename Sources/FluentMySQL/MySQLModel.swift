import Foundation

public protocol _MySQLModel: Model, MySQLTable where Self.Database == MySQLDatabase { }

extension _MySQLModel {
    /// See `SQLTable`.
    public static var sqlTableIdentifierString: String {
        return entity
    }
}

/// A MySQL database model.
/// See `Fluent.Model`.
public protocol MySQLModel: _MySQLModel where Self.ID == Int {
    /// This MySQL Model's unique identifier.
    var id: ID? { get set }
}

extension MySQLModel {
    /// See `Model.idKey`
    public static var idKey: IDKey { return \.id }
}

/// A MySQL database pivot.
/// See `Fluent.Pivot`.
public protocol MySQLPivot: Pivot, MySQLModel { }

/// A MySQL database UUID model.
/// See `Fluent.Model`.
public protocol MySQLUUIDModel: _MySQLModel where Self.ID == UUID {
    /// This MySQL Model's unique identifier.
    var id: UUID? { get set }
}

extension MySQLUUIDModel {
    /// See `Model.idKey`
    public static var idKey: IDKey { return \.id }
}

/// A MySQL database UUID pivot.
/// See `Fluent.Pivot`.
public protocol MySQLUUIDPivot: Pivot, MySQLUUIDModel { }


/// A MySQL database String model.
/// See `Fluent.Model`.
public protocol MySQLStringModel: _MySQLModel where Self.ID == String {
    /// This MySQL Model's unique identifier.
    var id: String? { get set }
}

extension MySQLStringModel {
    /// See `Model.idKey`
    public static var idKey: IDKey { return \.id }
}

/// A MySQL database String pivot.
/// See `Fluent.Pivot`.
public protocol MySQLStringPivot: Pivot, MySQLStringModel { }

public protocol MySQLMigration: Migration where Self.Database == MySQLDatabase { }
