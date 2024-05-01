/// Errors that may be thrown by this package.
enum FluentMySQLError: Error {
    /// ``FluentMySQLConfiguration/mysql(url:maxConnectionsPerEventLoop:connectionPoolTimeout:encoder:decoder:)`` was
    /// invoked with an invalid input.
    case invalidURL(String)
}
