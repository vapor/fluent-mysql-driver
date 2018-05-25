extension SchemaBuilder where Model.Database == MySQLDatabase {
    /// Adds a field. You can specify an optional data type for the field.
    ///
    ///     builder.field(type: .varChar(255), for: \.name)
    ///
    /// - parameters:
    ///     - keyPath: `KeyPath` to the field.
    ///     - dataType: Data type for the field.
    ///     - primaryKey: If `true`, override this field to be a `PRIMARY KEY` field.
    public func field<T>(for keyPath: KeyPath<Model, T>, dataType: MySQLDataType, primaryKey: Bool? = nil) {
        var dataType = dataType
        if primaryKey ?? (keyPath == Model.idKey) {
            dataType.addPrimaryKeyAttributes()
        }
        field(for: .fluentProperty(.keyPath(keyPath)), dataType: dataType.dataType)
    }
}
