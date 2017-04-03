import Fluent

extension Builder {
    public func index(
        _ column: String
    ) {
        raw("INDEX _fluent_index_\(column) (`\(column)`)")
    }
}

extension Builder {
    public func foreignKey<E: Entity>(
        _ localColumn: String,
        references foreignColumn: String,
        on entity: E.Type = E.self
        ) {
        raw("CONSTRAINT _fluent_foreignkey_\(localColumn)_\(foreignColumn) FOREIGN KEY (`\(localColumn)`) REFERENCES `\(E.entity)` (`\(foreignColumn)`)")
    }
}
