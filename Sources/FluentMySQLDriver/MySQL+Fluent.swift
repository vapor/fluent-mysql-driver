import FluentSQL

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
    
    public func close() -> EventLoopFuture<Void> {
        #warning("TODO: implement connectionPool.close()")
        fatalError("")
    }
    
    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return self.withConnection { conn in
            return closure(conn)
        }
    }
}

extension MySQLError: DatabaseError { }

extension MySQLConnection: Database {
    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return closure(self)
    }
    
    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        let sql = SQLQueryConverter().convert(query)
        return self.sqlQuery(sql) { row in
            try onOutput(row.fluentOutput)
        }.flatMapThrowing {
            switch query.action {
            case .create:
                let row = LastInsertRow(okPacket: self.lastOKPacket!)
                try onOutput(row)
            default: break
            }
        }
    }
    
    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        return self.sqlQuery(SQLSchemaConverter().convert(schema)) { row in
            fatalError("unexpected output")
        }
    }
    
    public func close() -> EventLoopFuture<Void> {
        #warning("TODO: implement connectionPool.close()")
        return self.eventLoop.makeSucceededFuture(())
    }
}

struct LastInsertRow: DatabaseOutput {
    var description: String {
        return "\(self.okPacket)"
    }
    
    let okPacket: MySQLProtocol.OK_Packet
    
    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        #warning("TODO: fixme, better logic")
        switch field {
        case "id":
            if T.self is Int.Type {
                return Int(self.okPacket.lastInsertID!) as! T
            } else {
                fatalError()
            }
        default: fatalError()
        }
    }
}
