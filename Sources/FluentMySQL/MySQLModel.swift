import Foundation

/// A MySQL database model.
/// See `Fluent.Model`.
public protocol MySQLModel: Model where Self.Database == MySQLDatabase, Self.ID == Int {
    /// This MySQL Model's unique identifier.
    var id: ID? { get set }
}

extension MySQLModel {
    /// See `Model.ID`
    public typealias ID = Int

    /// See `Model.idKey`
    public static var idKey: IDKey { return \.id }
}

/// A MySQL database pivot.
/// See `Fluent.Pivot`.
public protocol MySQLPivot: Pivot, MySQLModel { }

/// A MySQL database UUID model.
/// See `Fluent.Model`.
public protocol MySQLUUIDModel: Model where Self.Database == MySQLDatabase, Self.ID == UUID {
    /// This MySQL Model's unique identifier.
    var id: UUID? { get set }
}

extension MySQLUUIDModel {
    /// See `Model.ID`
    public typealias ID = UUID

    /// See `Model.idKey`
    public static var idKey: IDKey { return \.id }
}

/// A MySQL database UUID pivot.
/// See `Fluent.Pivot`.
public protocol MySQLUUIDPivot: Pivot, MySQLUUIDModel { }
