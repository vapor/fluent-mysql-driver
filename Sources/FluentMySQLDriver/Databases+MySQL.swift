import FluentSQL
import MySQLNIO

extension DatabaseID {
    public static var mysql: DatabaseID {
        return .init(string: "mysql")
    }
}

extension Databases {
    public mutating func mysql(
        configuration: MySQLConfiguration,
        poolConfiguration: ConnectionPoolConfig = .init(),
        as id: DatabaseID = .mysql,
        isDefault: Bool = true
    ) {
        let db = MySQLConnectionSource(
            configuration: configuration,
            on: self.eventLoop
        )
        let pool = ConnectionPool(config: poolConfiguration, source: db)
        self.add(pool, as: id, isDefault: isDefault)
    }
}
