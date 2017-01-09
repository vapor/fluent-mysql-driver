import Fluent

/**
    MySQL flavored SQL serializer.
*/
public final class MySQLSerializer: GeneralSQLSerializer {
    public override func sql(_ type: Schema.Field.DataType) -> String {
        switch type {
        case .id:
            return "INT(10) UNSIGNED PRIMARY KEY AUTO_INCREMENT"
        case .int:
            return "INT(11)"
        case .string(let length):
            if let length = length {
                return "VARCHAR(\(length))"
            } else {
                return "VARCHAR(255)" // TODO: This may need to be 191 if using `utf8mb4` encoding
            }
        case .double:
            return "DOUBLE"
        case .bool:
            return "TINYINT(1) UNSIGNED"
        case .data:
            return "BLOB"
        case .custom(let type):
            return type
        }
    }
}
