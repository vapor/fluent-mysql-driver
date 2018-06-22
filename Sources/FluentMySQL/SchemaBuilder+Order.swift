extension SchemaUpdater where Model: MySQLModel {
    public func order<A, B>(_ column: KeyPath<Model, A>, after: KeyPath<Model, B>) {
        schema.columnPositions[.keyPath(column)] = .after(.keyPath(after))
    }
    
    public func order<A>(first column: KeyPath<Model, A>) {
        schema.columnPositions[.keyPath(column)] = .first
    }
}
