import Fluent


public final class MySQLSerializer: GeneralSQLSerializer {
    public override func sql(_ column: SQL.Column) -> String {
        switch column {
        case .primaryKey:
            return sql("id") + " INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT"
        case .integer(let name):
            return sql(name) + " INT(11)"
        case .string(let name, let length):
            if let length = length {
                return sql(name) + " VARCHAR(\(length))"
            } else {
                return sql(name) + " VARCHAR(255)"
            }
        case .double(let name, let digits, let decimal):
            if let digits = digits, let decimal = decimal {
                return sql(name) + " DOUBLE(\(digits),\(decimal))"
            } else {
                return sql(name) + " DOUBLE"
            }
        }
    }
}
