import FluentSQL
import MySQLNIO

extension DatabaseID {
    public static var mysql: DatabaseID {
        return .init(string: "mysql")
    }
}

extension Databases {
    public func mysql(
        configuration: MySQLConfiguration,
        poolConfiguration: ConnectionPoolConfiguration = .init(),
        as id: DatabaseID = .mysql,
        isDefault: Bool = true,
        on eventLoopGroup: EventLoopGroup
    ) {
        let db = MySQLConnectionSource(
            configuration: configuration
        )
        let pool = ConnectionPool(configuration: poolConfiguration, source: db, on: eventLoopGroup)
        self.add(MySQLDatabaseDriver(pool: pool), as: id, isDefault: isDefault)
    }
}
