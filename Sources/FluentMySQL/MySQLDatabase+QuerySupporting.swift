import Async
import FluentSQL
import Foundation

/// Adds ability to do basic Fluent queries using a `MySQLDatabase`.
extension MySQLDatabase: QuerySupporting, CustomSQLSupporting {
    /// See `QuerySupporting`.
    public typealias QueryData = MySQLData

    /// See `QuerySupporting`.
    public typealias QueryField = MySQLColumn

    /// See `QuerySupporting`.
    public typealias QueryFilter = DataPredicateComparison

    /// See `QuerySupporting.execute`
    public static func execute(
        query: DatabaseQuery<MySQLDatabase>,
        into handler: @escaping ([QueryField: MySQLData], MySQLConnection) throws -> (),
        on connection: MySQLConnection
    ) -> EventLoopFuture<Void> {
        return Future<Void>.flatMap(on: connection) {
            // Convert Fluent `DatabaseQuery` to generic FluentSQL `DataQuery`
            var (sqlQuery, bindValues) = query.makeDataQuery()
            let params: [MySQLDatabase.QueryData]

            switch sqlQuery {
            case .manipulation(var manipulation):
                // If the query has an Encodable model attached serialize it.
                // Dictionary keys should be added to the DataQuery as columns.
                // Dictionary values should be added to the parameterized array.
                var modelData: [MySQLData] = []
                modelData.reserveCapacity(query.data.count)
                manipulation.columns = query.data.map { (field, data) in
                    modelData.append(data)
                    let col = DataColumn(table: field.table, name: field.name)
                    return .init(column: col, value: .placeholder)
                }
                params = modelData + bindValues
                sqlQuery = .manipulation(manipulation)
            case .query(let data):
                params = bindValues
                sqlQuery = .query(data)
            case .definition:
                params = []
            }

            /// Apply custom sql transformations
            for customSQL in query.customSQL {
                customSQL.closure(&sqlQuery)
            }

            // Create a MySQL-flavored SQL serializer to create a SQL string
            let sqlSerializer = MySQLSerializer()
            let sqlString = sqlSerializer.serialize(sqlQuery)

            /// Log supporting
            if let logger = connection.logger {
                logger.record(query: sqlString, values: params.map { $0.description })
            }

            /// Run the query
            return connection.query(sqlString,params) { row in
                try handler(row, connection)
            }
        }
    }

    /// See `QuerySupporting.modelEvent`
    public static func modelEvent<M>(event: ModelEvent, model: M, on connection: MySQLConnection) -> Future<M>
        where MySQLDatabase == M.Database, M: Model
    {
        switch event {
        case .willCreate:
            if M.ID.self == UUID.self {
                var model = model
                model.fluentID = UUID() as? M.ID
                return Future.map(on: connection) { model }
            }
        case .didCreate:
            if M.ID.self == Int.self {
                return connection.simpleQuery("SELECT LAST_INSERT_ID() AS lastval;").map(to: M.self) { row in
                    var model = model
                    try model.fluentID = row[0].firstValue(forColumn: "lastval")?.decode(Int.self) as? M.ID
                    return model
                }
            }
        default: break
        }

        return Future.map(on: connection) { model }
    }

    /// See `QuerySupporting`.
    public static func queryDataEncode<T>(_ data: T?) throws -> MySQLData {
        if let data = data {
            guard let convertible = data as? MySQLDataConvertible else {
                throw MySQLError(identifier: "queryDataSerialize", reason: "Cannot serialize \(T.self) to MySQLData", source: .capture())
            }
            return try convertible.convertToMySQLData()
        } else {
            return MySQLData.null
        }
    }

    /// See `QuerySupporting`.
    public static func queryField(for reflectedProperty: ReflectedProperty, entity: String) throws -> MySQLColumn {
        return .init(table: entity, name: reflectedProperty.path.first ?? "")
    }

    /// See `QuerySupporting`.
    public static func queryEncode<E>(_ encodable: E, entity: String) throws -> [MySQLColumn: MySQLData]
        where E: Encodable
    {
        return try MySQLRowEncoder().encode(encodable)
    }

    /// See `QuerySupporting`.
    public static func queryDecode<D>(_ data: [MySQLColumn: MySQLData], entity: String, as decodable: D.Type) throws -> D
        where D: Decodable
    {
        return try MySQLRowDecoder().decode(D.self, from: data.filter { $0.key.table == nil || $0.key.table == entity })
    }
}

extension MySQLData: FluentData { }
extension MySQLColumn: DataColumnRepresentable {
    public func makeDataColumn() -> DataColumn {
        return .init(table: table, name: name)
    }
}
