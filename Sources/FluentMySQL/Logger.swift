import Async
import MySQL

/// A MySQL logger.
public protocol MySQLLogger {
    /// Log the query.
    func log(query: MySQLQuery)
}

extension DatabaseLogger: MySQLLogger {
    /// See MySQLLogger.log
    public func log(query: MySQLQuery) {
        let log = DatabaseLog(query: query.queryString)
        record(log: log)
    }
}
