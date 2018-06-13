//import Crypto
//
///// MySQL-specific serializer.
//internal class MySQLSerializer: SQLSerializer {
//    /// Creates a new `MySQLSerializer`
//    init() { }
//
//    /// See `SQLSerializer`.
//    func makeEscapedString(from string: String) -> String {
//        return "`\(string)`"
//    }
//
//    /// See `SQLSerializer`.
//    func makePlaceholder(name: String) -> String {
//        return "?"
//    }
//    
//    /// See `SQLSerializer`.
//    func serialize(conflict: SQLQuery.DML.Conflict, binds: inout Binds) -> String {
//        var sql: [String] = []
//        sql.append("ON DUPLICATE KEY UPDATE")
//        sql.append(conflict.values.map { data in
//            serialize(column: data.key, value: data.value, binds: &binds)
//        }.joined(separator: ", "))
//        return sql.joined(separator: " ")
//    }
//
//    /// See `SQLSerializer`.
//    func makeName(for constraint: SQLQuery.DDL.Constraint) -> String {
//        let type: String
//        let name: String
//        switch constraint.storage {
//        case .foreignKey(let foreignKey):
//            type = "fk"
//            name = "\(foreignKey.local.table ?? "").\(foreignKey.local.name)_\(foreignKey.foreign.table ?? "").\(foreignKey.foreign.name)"
//        case .unique(let unique):
//            type = "uq"
//            name = unique.columns.map { "\($0.table ?? "").\($0.name)" }.joined(separator: "_")
//        }
//        do {
//            return try "fluent:\(type):" + MD5.hash(name).base64URLEncodedString()
//        } catch {
//            return name
//        }
//    }
//}
