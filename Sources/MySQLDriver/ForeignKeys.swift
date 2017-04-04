import Fluent

extension Builder {
    /// Adds an index to the column.
    public func index(_ column: String) {
        raw("INDEX _fluent_index_\(column) (`\(column)`)")
    }

    /// Adds a foreign key constraint from a local
    /// column to a column on the foreign entity.
    public func foreignKey<E: Entity>(
        _ localColumn: String,
        references foreignColumn: String,
        on entity: E.Type = E.self
    ) {
        raw("CONSTRAINT _fluent_foreignkey_\(localColumn)_\(foreignColumn) FOREIGN KEY (`\(localColumn)`) REFERENCES `\(E.entity)` (`\(foreignColumn)`)")
    }
}
