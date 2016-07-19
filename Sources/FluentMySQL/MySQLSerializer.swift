import Fluent

/**
    MySQL flavored SQL serializer.
*/
public final class MySQLSerializer: GeneralSQLSerializer {
    public override func sql(_ type: Schema.Field.DataType) -> String {
        switch type {
        case .id:
            return "INT(11) PRIMARY KEY AUTO_INCREMENT"
        case .int:
            return "INT(11)"
        case .string(let length):
            if let length = length {
                return "VARCHAR(\(length))"
            } else {
                return "VARCHAR(255)"
            }
        case .double:
            return "DOUBLE"
        case .bool:
            return "BIT"
        case .data:
            return "BLOB"
        }
    }
}
