import FluentSQL

/// An implementation of `SQLConverterDelegate` for MySQL .
struct MySQLConverterDelegate: SQLConverterDelegate {
    // See `SQLConverterDelegate.customDataType(_:)`.
    func customDataType(_ dataType: DatabaseSchema.DataType) -> (any SQLExpression)? {
        switch dataType {
        case .string: SQLRaw("VARCHAR(255)")
        case .datetime: SQLRaw("DATETIME(6)")
        case .uuid: SQLRaw("VARBINARY(16)")
        case .bool: SQLRaw("BOOL")
        case .array: SQLRaw("JSON")
        default: nil
        }
    }

    // See `SQLConverterDelegate.beforeConvert(_:)`.
    func beforeConvert(_ schema: DatabaseSchema) -> DatabaseSchema {
        var copy = schema
        // convert field foreign keys to table-level foreign keys
        // since mysql doesn't support the `REFERENCES` syntax
        //
        // https://stackoverflow.com/questions/14672872/difference-between-references-and-foreign-key
        copy.createFields = schema.createFields.map { field -> DatabaseSchema.FieldDefinition in
            switch field {
            case .definition(let name, let dataType, let constraints):
                return .definition(
                    name: name,
                    dataType: dataType,
                    constraints: constraints.filter { constraint in
                        switch constraint {
                        case .foreignKey(let schema, let space, let field, let onDelete, let onUpdate):
                            copy.createConstraints.append(
                                .constraint(
                                    .foreignKey([name], schema, space: space, [field], onDelete: onDelete, onUpdate: onUpdate),
                                    name: nil
                                ))
                            return false
                        default:
                            return true
                        }
                    }
                )
            case .custom(let any):
                return .custom(any)
            }
        }
        return copy
    }
}
