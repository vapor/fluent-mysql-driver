import FluentSQL

struct MySQLConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression? {
        switch dataType {
        case .string: return SQLRaw("VARCHAR(255)")
        case .datetime: return SQLRaw("DATETIME(6)")
        case .uuid: return SQLRaw("VARBINARY(16)")
        default: return nil
        }
    }

    func nestedFieldExpression(_ column: String, _ path: [String]) -> SQLExpression {
        return SQLRaw("JSON_EXTRACT(\(column), '$.\(path[0])')")
    }
}
