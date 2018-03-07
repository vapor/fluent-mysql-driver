import Async
import CodableKit
import FluentSQL
import Foundation

/// Adds ability to do basic Fluent queries using a `MySQLDatabase`.
extension MySQLDatabase: QuerySupporting, CustomSQLSupporting {
    /// See `QuerySupporting.execute`
    public static func execute(
        query: DatabaseQuery<MySQLDatabase>,
        into handler: @escaping ([QueryField: MySQLDataConvertible], MySQLConnection) throws -> (),
        on connection: MySQLConnection
    ) -> EventLoopFuture<Void> {
        return Future<Void>.flatMap(on: connection) {
            // Convert Fluent `DatabaseQuery` to generic FluentSQL `DataQuery`
            var (sqlQuery, bindValues) = query.makeDataQuery()

            // If the query has an Encodable model attached serialize it.
            // Dictionary keys should be added to the DataQuery as columns.
            // Dictionary values should be added to the parameterized array.
            var modelData: [MySQLDataConvertible] = []
            modelData.reserveCapacity(query.data.count)
            for (field, data) in query.data {
                sqlQuery.columns.append(DataColumn(table: field.entity, name: field.name))
                modelData.append(data)
            }

            /// Apply custom sql transformations
            for customSQL in query.customSQL {
                customSQL.closure(&sqlQuery)
            }

            // Create a MySQL-flavored SQL serializer to create a SQL string
            let sqlSerializer = MySQLSerializer()
            let sqlString = sqlSerializer.serialize(data: sqlQuery)

            /// Log supporting
            if let logger = connection.logger {
                logger.log(query: sqlString)
            }

            /// Run the query
            return connection.query(sqlString, modelData + bindValues) { row in
                var res: [QueryField: MySQLDataConvertible] = [:]
                for (col, data) in row {
                    let field = QueryField(entity: col.table, name: col.name)
                    res[field] = data
                }
                try handler(res, connection)
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
                return connection.simpleQuery("SELECT LASTVAL();").map(to: M.self) { row in
                    var model = model
                    try model.fluentID = row[0]["lastval"]?.decode(Int.self) as? M.ID
                    return model
                }
            }
        default: break
        }

        return Future.map(on: connection) { model }
    }

    /// See `QuerySupporting.queryDataParse(_:from:)`
    public static func queryDataParse<T>(_ type: T.Type, from data: MySQLDataConvertible) throws -> T {
        guard let convertibleType = T.self as? MySQLDataConvertible.Type else {
            throw MySQLError(identifier: "queryDataParse", reason: "Cannot parse \(T.self) from MySQLData", source: .capture())
        }
        return try convertibleType.convertFromMySQLData(data.convertToMySQLData()) as! T
    }

    /// See `QuerySupporting.queryDataSerialize(data:)`
    public static func queryDataSerialize<T>(data: T?) throws -> MySQLDataConvertible {
        if let data = data {
            guard let convertible = data as? MySQLDataConvertible else {
                throw MySQLError(identifier: "queryDataSerialize", reason: "Cannot serialize \(T.self) to MySQLData", source: .capture())
            }
            return try convertible.convertToMySQLData()
        } else {
            return MySQLData.null
        }
    }
}

