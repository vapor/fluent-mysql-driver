import Async
import CodableKit
import Fluent
import FluentSQL
import Foundation
import MySQL
import SQL

/// A Fluent wrapper around a MySQL connection that can log
public final class FluentMySQLConnection: DatabaseConnection {
    public typealias Config = FluentMySQLConfig
    
    public func close() {
        self.connection.close()
    }

    public func existingConnection<D>(to type: D.Type) -> D.Connection? where D : Database {
        return self as? D.Connection
    }
    
    /// Respresents the current FluentMySQLConnection as a connection to `D`
    public func connect<D>(to database: DatabaseIdentifier<D>) -> Future<D.Connection> {
        fatalError("Call `.existingConnection` first.")
    }
    
    /// Keeps track of logs by MySQL
    let logger: DatabaseLogger?
    
    /// The underlying MySQL Connection that can be used for normal queries
    public let connection: MySQLConnection
    
    /// Used to create a new FluentMySQLConnection wrapper
    init(connection: MySQLConnection, logger: DatabaseLogger?) {
        self.connection = connection
        self.logger = logger
    }
}

extension FluentMySQLConnection: QueryExecuting {
    /// See QueryExecuting.execute
    public func execute<I, D>(query: DatabaseQuery, into stream: I) where I: Async.InputStream, D == I.Input, D: Decodable {
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

        if let logger = self.logger {
            let log = DatabaseLog(
                query: sqlString,
                values: ["\(query.data.debugDescription)"] + binds.map { "\($0.encodable)" },
                date: .init()
            )
            logger.record(log: log)
        }
        
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


    /// See QueryExecuting.setID
    public func setID<M>(on model: M) throws where M : Model {
        guard let raw = connection.lastInsertID else {
            fatalError("Connection was expected to have a last insert ID.")
        }

        guard let type = M.ID.self as? MySQLLastInsertIDConvertible.Type else {
            fatalError("\(M.self) ID is not MySQLLastInsertIDConvertible")
        }

        model[keyPath: M.idKey] = type.convert(from: raw) as? M.ID
    }

    /// See QueryExecuting.execute
    public func nextFluentID<T>() throws -> T where T: Fluent.ID {
        guard T.self is UUID.Type else {
            fatalError()
        }

        return UUID() as! T
    }
}

extension FluentMySQLConnection: ReferenceConfigurable {
    /// ReferenceSupporting.enableReferences
    public func enableReferences() -> Future<Void> {
        return connection.administrativeQuery("SET FOREIGN_KEY_CHECKS=1;")
    }

    /// ReferenceSupporting.disableReferences
    public func disableReferences() -> Future<Void> {
        return connection.administrativeQuery("SET FOREIGN_KEY_CHECKS=0;")
    }
}

func cast<T>(_ int: UInt64, to: T.Type) -> T where T: BinaryInteger {
    return numericCast(int)
}

/// A MySQL query serializer
internal final class MySQLSerializer: SQLSerializer {
    internal init () {}
}
