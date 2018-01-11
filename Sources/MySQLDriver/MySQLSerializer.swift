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
                if primaryKey {
                    typeString = "CHAR(36) PRIMARY KEY"
                } else {
                    typeString = "CHAR(36)"
                }
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
    
    public override func deleteIndex(_ idx: RawOr<Index>) -> (String, [Node]) {
        var statement: [String] = []
        
        statement.append("ALTER TABLE")
        statement.append(escape(E.entity))
        statement.append("DROP INDEX")
        
        switch idx {
        case .raw(let raw, _):
            statement.append(raw)
        case .some(let idx):
            statement.append(escape(idx.name))
        }
        
        return (
            concatenate(statement),
            []
        )
    }


    public func alter(
        add fs: [RawOr<Field>],
        _ fks: [RawOr<ForeignKey>],
        delete dfs: [RawOr<Field>],
        _ dfks: [RawOr<ForeignKey>]
        ) -> (String, [Node]) {
        var statement: [String] = []

        statement += "ALTER TABLE"
        statement += escape(E.entity)

        var subclause: [String] = []

        for field in fs {
            subclause += "ADD " + column(field)
        }

        for fk in fks {
            subclause += "ADD " + foreignKey(fk)
        }

        for field in dfs {
            let name: String
            switch field {
            case .raw(let raw, _):
                name = raw
            case .some(let some):
                name = some.name
            }
            subclause += "DROP " + escape(name)
        }

        for fk in dfks {
            switch fk {
            case .raw(let raw, _):
                subclause += "DROP FOREIGN KEY " + raw
            case .some(let some):
                subclause += "DROP FOREIGN KEY " + escape(some.name)
            }
        }

        statement += subclause.joined(separator: ", ")

        return (
            concatenate(statement),
            []
        )
    }


    public override func limit(_ limit: RawOr<Limit>) -> String {
        var statement: [String] = []
        
        statement += "LIMIT"
        switch limit {
        case .raw(let raw, _):
            statement += raw
        case .some(let some):
            if query.action == .delete {
                if some.offset != 0 {
                    print("[Fluent] [Warning] You cannot specify offsets in a delete query.")
                }
                statement += "\(some.count)"
            } else {
                statement += "\(some.offset), \(some.count)"
            }
        }
        
        return statement.joined(separator: " ")
    }
}
