import MySQL
import Fluent

public class MySQLConnection: Fluent.Connection {
    public var closed: Bool
    public var connection: MySQL.Connection
    
    public init(connection: MySQL.Connection) {
        self.connection = connection
        closed = false
    }
    
    /// @see Fluent.Executor
    @discardableResult
    public func query<T: Entity>(_ query: Query<T>) throws -> Node {
        let serializer = MySQLSerializer(sql: query.sql)
        let (statement, values) = serializer.serialize()
        
        let results = try mysql(statement, values)
        
        if query.action == .create {
            let insert = try mysql("SELECT LAST_INSERT_ID() as id", [])
            if
                case .array(let array) = insert,
                let first = array.first,
                case .object(let obj) = first,
                let id = obj["id"]
            {
                return id
            }
        }
        
        return results
    }
    
    /// @see Fluent.Executor
    public func schema(_ schema: Schema) throws {
        let serializer = MySQLSerializer(sql: schema.sql)
        let (statement, values) = serializer.serialize()
        
        try mysql(statement, values)
    }
    
    /// @see Fluent.Executor
    @discardableResult
    public func raw(_ query: String, _ values: [Node] = []) throws -> Node {
        return try mysql(query, values)
    }
    
    /// Provides access to the underlying MySQL database
    /// for running raw queries.
    @discardableResult
    public func mysql(_ query: String, _ values: [Node] = []) throws -> Node {
        let values = values.map({ $0 as NodeRepresentable })
        do {
            let results = try connection.execute(query, values)
            .map { Node.object($0) }
            return .array(results)
        } catch MySQL.Error.connection(let reason) {
            closed = true
            throw MySQL.Error.connection(reason)
        }
    }
}
