import Fluent
import MySQL

public final class Connection: Fluent.Connection {
    public let mysqlConnection: MySQL.Connection
    public var queryLogger: QueryLogger?
    public var isClosed: Bool {
        return mysqlConnection.isClosed
    }
    
    public init(_ conn: MySQL.Connection) {
        mysqlConnection = conn
    }
    
    /// Executes a `Query` from and
    /// returns an array of results fetched,
    /// created, or updated by the action.
    ///
    /// Drivers that support raw querying
    /// accept string queries and parameterized values.
    ///
    /// This allows Fluent extensions to be written that
    /// can support custom querying behavior.
    @discardableResult
    public func query<E: Entity>(_ query: RawOr<Query<E>>) throws -> Node {
        switch query {
        case .raw(let raw, let values):
            return try mysql(raw, values)
        case .some(let query):
            let serializer = MySQLSerializer(query)
            let (statement, values) = serializer.serialize()
            let results = try mysql(statement, values)
            
            if query.action == .create {
                let insert = try mysql("SELECT LAST_INSERT_ID() as id", [])
                if
                    case .array(let array) = insert.wrapped,
                    let first = array.first,
                    case .object(let obj) = first,
                    let id = obj["id"]
                {
                    return Node(id, in: insert.context)
                }
            }
            
            return results
        }
    }
    
    @discardableResult
    private func mysql(_ query: String, _ values: [Node] = []) throws -> Node {
        queryLogger?.log(query, values)
        do {
            return try mysqlConnection.execute(
                query,
                values as [NodeRepresentable]
            )
        } catch let error as MySQLError
            where
                error.code == .serverLost ||
                error.code == .serverGone ||
                error.code == .serverLostExtended
        {
            throw QueryError.connectionClosed(error)
        }
    }
}
