extension MySQLError: DatabaseError {
    public var isSyntaxError: Bool {
        return false
    }

    public var isConstraintFailure: Bool {
        switch self {
            case .duplicateEntry(_):
                return true
            
            default:
                return false
        }
    }

    public var isConnectionClosed: Bool {
        return false
    }
}
