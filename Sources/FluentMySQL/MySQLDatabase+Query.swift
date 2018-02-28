import Async
import CodableKit
import Foundation
import SQL

extension MySQLDatabase: QuerySupporting {
    /// See QuerySupporting.execute
    public static func execute<I, D>(
        query: DatabaseQuery<MySQLDatabase>,
        into stream: I,
        on connection: MySQLConnection
    ) where I: Async.InputStream, D: Decodable, D == I.Input {
        /// convert fluent query to an abstract SQL query
        var (dataQuery, binds) = query.makeDataQuery()

        if let model = query.data {
            // Encode the model to read it's keys to be used inside the query
            let encoder = CodingPathKeyPreEncoder()

            do {
                dataQuery.columns += try encoder.keys(for: model).compactMap { keys in
                    guard let key = keys.first else {
                        return nil
                    }

                    return DataColumn(name: key)
                }
            } catch {
                // Close the stream with an error
                stream.error(error)
                stream.close()
                return
            }
        }

        /// Create a MySQL query string
        let sqlString = MySQLSerializer().serialize(data: dataQuery)
        _logger?.log(query: sqlString)

        if query.data == nil && binds.count == 0 {
            do {
                try connection.stream(D.self, in: sqlString, to: stream)
            } catch {
                stream.error(error)
                stream.close()
            }
            return
        }

        // Prepares the statement for binding
        connection.withPreparation(statement: sqlString) { context -> Future<Void> in
            do {
                // Binds the model and other values
                let bound = try context.bind { binding in
                    try binding.withEncoder { encoder in
                        if let model = query.data {
                            try model.encode(to: encoder)
                        }

                        for bind in binds {
                            try bind.encodable.encode(to: encoder)
                        }
                    }
                }

                // Streams all results into the parameter-provided stream
                try bound.stream(D.self, to: stream)
                
                return Future<Void>(())
            } catch {
                // Close the stream with an error
                stream.error(error)
                stream.close()
                return Future(error: error)
            }
        }.catch { error in
            // Close the stream with an error
            stream.error(error)
            stream.close()
        }
    }

    public static func modelEvent<M>(event: ModelEvent, model: M, on connection: MySQLConnection) -> Future<M> where MySQLDatabase == M.Database, M : Model {
        var model = model
        
        switch event {
        case .willCreate:
            if M.ID.self == UUID.self {
                model.fluentID = UUID() as? M.ID
            }
        case .didCreate:
            if let id = connection.lastInsertID {
                if M.ID.self == Int.self {
                    model.setId(to: id, type: Int.self)
                } else if M.ID.self == Int.self {
                    model.setId(to: id, type: Int.self)
                } else if M.ID.self == Int8.self {
                    model.setId(to: id, type: Int8.self)
                } else if M.ID.self == Int16.self {
                    model.setId(to: id, type: Int16.self)
                } else if M.ID.self == Int32.self {
                    model.setId(to: id, type: Int32.self)
                } else if M.ID.self == Int64.self {
                    model.setId(to: id, type: Int64.self)
                } else if M.ID.self == UInt8.self {
                    model.setId(to: id, type: UInt8.self)
                } else if M.ID.self == UInt16.self {
                    model.setId(to: id, type: UInt16.self)
                } else if M.ID.self == UInt32.self {
                    model.setId(to: id, type: UInt32.self)
                } else if M.ID.self == UInt64.self {
                    model.setId(to: id, type: UInt64.self)
                }
            }
        default: break
        }
        
        return Future(model)
    }
}

extension Model {
    fileprivate mutating func setId<T: BinaryInteger>(to int: UInt64, type: T.Type) {
        self.fluentID = ((numericCast(int) as T) as! ID)
    }
}
