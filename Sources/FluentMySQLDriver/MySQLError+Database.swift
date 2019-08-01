extension MySQLError: DatabaseError {
    public var isSyntaxError: Bool {
        return false
    }

    public var isConstraintFailure: Bool {
        return false
    }

    public var isConnectionClosed: Bool {
        return false
    }
}
