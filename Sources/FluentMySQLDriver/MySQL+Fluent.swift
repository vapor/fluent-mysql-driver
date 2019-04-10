import FluentSQL
import NIOMySQL

extension DatabaseID {
    public static var mysql: DatabaseID {
        return .init(string: "mysql")
    }
}

extension Databases {
    public mutating func mysql(
        configuration: MySQLConfiguration,
        poolConfiguration: ConnectionPoolConfig = .init(),
        as id: DatabaseID = .mysql,
        isDefault: Bool = true
    ) {
        let db = MySQLConnectionSource(
            configuration: configuration,
            on: self.eventLoop
        )
        let pool = ConnectionPool(config: poolConfiguration, source: db)
        self.add(pool, as: id, isDefault: isDefault)
    }
}

extension ConnectionPool: Database where Source.Connection: Database {
    public var eventLoop: EventLoop {
        return self.source.eventLoop
    }
    
    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        return self.withConnection { $0.execute(schema) }
    }
    
    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        return self.withConnection { $0.execute(query, onOutput) }
    }
    
    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return self.withConnection { conn in
            return closure(conn)
        }
    }
}

extension MySQLError: DatabaseError { }

private struct MySQLConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression? {
        switch dataType {
        case .string: return SQLRaw("VARCHAR(255)")
        case .datetime: return SQLRaw("DATETIME(6)")
        default: return nil
        }
    }
    
    func nestedFieldExpression(_ column: String, _ path: [String]) -> SQLExpression {
        return SQLRaw("JSON_EXTRACT(\(column), '$.\(path[0])')")
    }
}

extension MySQLConnection: Database {
    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return closure(self)
    }
    
    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        let sql = SQLQueryConverter(delegate: MySQLConverterDelegate()).convert(query)
        var serializer = SQLSerializer(dialect: MySQLDialect())
        sql.serialize(to: &serializer)
        return self.query(serializer.sql, serializer.binds.map { encodable in
            return try! MySQLDataEncoder().encode(encodable)
        }, onRow: { row in
            try! onOutput(row.fluentOutput)
        }, onMetadata: { metadata in
            let row = LastInsertRow(metadata: metadata)
            try! onOutput(row)
        })
    }
    
    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        return self.sqlQuery(SQLSchemaConverter(delegate: MySQLConverterDelegate()).convert(schema)) { row in
            fatalError("unexpected output")
        }
    }
}

struct LastInsertRow: DatabaseOutput {
    var description: String {
        return "\(self.metadata)"
    }
    
    let metadata: MySQLQueryMetadata
    
    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        #warning("TODO: fixme, better logic")
        switch field {
        case "fluentID":
            if T.self is Int.Type {
                return Int(self.metadata.lastInsertID!) as! T
            } else {
                fatalError()
            }
        default: throw ModelError.missingField(name: field)
        }
    }
}
