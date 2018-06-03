extension SchemaBuilder where Model.Database == MySQLDatabase {
    /// Adds a field. You can specify an optional data type for the field.
    ///
    ///     builder.field(type: .varChar(255), for: \.name)
    ///
    /// - parameters:
    ///     - keyPath: `KeyPath` to the field.
    ///     - type: Data type for the field.
    ///     - primaryKey: If `true`, override this field to be a `PRIMARY KEY` field.
    public func field<T>(for keyPath: KeyPath<Model, T>, type: MySQLDataType, primaryKey: Bool? = nil, autoIncrement: Bool = false) {
        var type = SQLQuery.DDL.ColumnDefinition.ColumnType.init(name: type.name, parameters: type.parameters, attributes: type.attributes)
        if primaryKey ?? (keyPath == Model.idKey) {
            type.attributes.append("PRIMARY KEY")
        }
        if autoIncrement {
            type.attributes.append("AUTO_INCREMENT")
        }
        field(for: .fluentProperty(.keyPath(keyPath)), type: type)
    }
}
