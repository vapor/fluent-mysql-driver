import Fluent

/// MySQL flavored SQL serializer.
public final class MySQLSerializer<E: Entity>: GeneralSQLSerializer<E> {
    public override func type(_ type: Field.DataType, primaryKey: Bool) -> String {
        switch type {
        case .id(let type):
            let typeString: String
            switch type {
            case .int:
                if primaryKey {
                    typeString = "INT(10) UNSIGNED PRIMARY KEY AUTO_INCREMENT"
                } else {
                    typeString = "INT(10) UNSIGNED"
                }
            case .uuid:
                typeString = "CHAR(36)"
            case .custom(let custom):
                typeString = custom
            }
            return typeString
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
        case .bytes:
            return "BLOB"
        case .date:
            return "DATETIME"
        case .custom(let type):
            return type
        }
    }
}
