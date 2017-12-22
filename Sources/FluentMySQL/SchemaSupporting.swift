import Foundation
import Async
import SQL
import Fluent
import FluentSQL
import MySQL

extension FluentMySQLConnection : SchemaExecuting, TransactionExecuting {
    /// Runs a transaction on the MySQL connection
    public func execute(transaction: DatabaseTransaction<FluentMySQLConnection>) -> Future<Void> {
        let promise = Promise<Void>()
        
        connection.administrativeQuery("START TRANSACTION").flatMap(to: Void.self) {
            return transaction.run(on: self)
        }.addAwaiter { result in
            if let error = result.error {
                self.connection.administrativeQuery("ROLLBACK").do {
                    // still fail even though rollback succeeded
                    promise.fail(error)
                }.catch { error in
                    promise.fail(error)
                }
            } else {
                promise.complete()
            }
        }
        
        return promise.future
    }
    
    public typealias FieldType = ColumnType
    
    /// Executes the schema query
    public func execute<D>(schema: DatabaseSchema<D>) -> Future<Void> {
        var query = schema.makeSchemaQuery()
        switch query.statement {
        case .create(let cols, _):
            query.statement = .create(columns: cols, foreignKeys: (schema as! DatabaseSchema<MySQLDatabase>).makeForeignKeys())
        default: break
        }
        let sqlString =  MySQLSerializer().serialize(schema: query)
        if let logger = self.logger {
            let log = DatabaseLog(
                query: sqlString,
                values: [],
                date: .init()
            )
            _ = logger.record(log: log)
        }
        return connection.administrativeQuery(sqlString)
    }
}
