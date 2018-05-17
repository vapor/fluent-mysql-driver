import Async
import FluentSQL
import Foundation

/// Adds ability to do basic Fluent queries using a `MySQLDatabase`.
extension MySQLDatabase: QuerySupporting, CustomSQLSupporting {
    /// See `QuerySupporting`.
    public typealias DataType = MySQLData

    /// See `QuerySupporting`.
    public typealias FieldType = MySQLColumn

    /// See `QuerySupporting`.
    public typealias FilterType = DataPredicateComparison

    public typealias ValueType = DataPredicateValue

    /// See `QuerySupporting`.
    public typealias EntityType = [MySQLColumn: MySQLData]

    /// See `QuerySupporting.execute`
    public static func execute(
        query: Query<MySQLDatabase>,
        into handler: @escaping ([MySQLColumn: MySQLData], MySQLConnection) throws -> (),
        on connection: MySQLConnection
    ) -> EventLoopFuture<Void> {
        return Future<Void>.flatMap(on: connection) {
            // Convert Fluent `DatabaseQuery` to generic FluentSQL `DataQuery`
            var (sqlQuery, bindEncodables) = try query.converToDataQuery()
            let params: [MySQLDatabase.DataType]

            let bindValues: [MySQLData] = try bindEncodables.map { encodable in
                guard let convertible = encodable as? MySQLDataConvertible else {
                    throw MySQLError(identifier: "mysqlData", reason: "\(encodable) is not `MySQLDataConvertible`", source: .capture())
                }
                return try convertible.convertToMySQLData()
            }

            switch sqlQuery {
            case .manipulation(var manipulation):
                var manipulationValues: [MySQLData] = []
                // If the query has an Encodable model attached serialize it.
                // Dictionary keys should be added to the DataQuery as columns.
                // Dictionary values should be added to the parameterized array.
                switch query.data {
                case .custom(let row):
                    manipulationValues.reserveCapacity(row.count)
                    manipulation.columns = row.map { (field, data) in
                        manipulationValues.append(data)
                        let col = DataColumn(table: field.table, name: field.name)
                        return .init(column: col, value: .placeholder)
                    }
                case .encodable(let encodable):
                    let encodableData = try MySQLRowEncoder().anyEncode(encodable)
                    manipulationValues.reserveCapacity(encodableData.count)
                    manipulation.columns = encodableData.map { (field, data) in
                        manipulationValues.append(data)
                        let col = DataColumn(table: field.table, name: field.name)
                        return .init(column: col, value: .placeholder)
                    }
                case .field(let field, let value):
                    let col = try field.convertToDataColumn()
                    switch value {
                    case .field(let field):
                        manipulation.columns = try [.init(column: col, value: .column(field.convertToDataColumn()))]
                    case .custom: fatalError()
                    case .encodables(let e):
                        manipulation.columns = [.init(column: col, value: .placeholder)]
                        manipulationValues = try [(e[0] as! MySQLDataConvertible).convertToMySQLData()]
                    }
                case .none: break
                }
                params = manipulationValues + bindValues
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
    public static func fieldType(for reflectedProperty: ReflectedProperty, entity: String) throws -> MySQLColumn {
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

extension MySQLColumn: DataColumnRepresentable {
    public func convertToDataColumn() -> DataColumn {
        return .init(table: table, name: name)
    }
}
