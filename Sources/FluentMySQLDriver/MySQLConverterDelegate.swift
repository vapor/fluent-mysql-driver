import FluentSQL

struct MySQLConverterDelegate: SQLConverterDelegate {
    func nestedFieldExpression(_ column: String, _ path: [String]) -> SQLExpression {
        let path = path.joined(separator: ".")
        return SQLRaw("JSON_EXTRACT(\(column), '$.\(path)')")
    }

    func customDataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression? {
        switch dataType {
        case .string: return SQLRaw("VARCHAR(255)")
        case .datetime: return SQLRaw("DATETIME(6)")
        case .uuid: return SQLRaw("VARBINARY(16)")
        case .bool: return SQLRaw("BOOL")
        case .array: return SQLRaw("JSON")
        default: return nil
        }
    }

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
                        case .foreignKey(let schema, let field, let onDelete, let onUpdate):
                            copy.createConstraints.append(.constraint(
                                .foreignKey([name], schema, [field], onDelete: onDelete, onUpdate: onUpdate),
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
