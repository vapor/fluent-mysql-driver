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
                dataQuery.columns += try encoder.keys(for: model).flatMap { keys in
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

        /// FIXME
        // _ = self.logger?.log(query: sqlString)

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
                try bound.stream(D.self, in: sqlString, to: stream)
                // try bound.stream(D.self, in: _, to: stream)

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

    /// See QuerySupporting.modelEvent
    public static func modelEvent<M>(
        event: ModelEvent,
        model: M,
        on connection: MySQLConnection
    ) -> Future<Void> where MySQLDatabase == M.Database, M: Model {
        switch event {
        case .willCreate:
            switch id(M.ID.self) {
            case id(UUID.self): model.fluentID = UUID() as? M.ID
            default: break
            }
        case .didCreate:
            switch id(M.ID.self) {
            case id(Int.self):
                if let id = connection.lastInsertID, id < numericCast(Int.max) {
                    model.fluentID = (numericCast(id) as Int) as? M.ID
                }
            default: break
            }
        default: break
        }

        return .done
    }
}
