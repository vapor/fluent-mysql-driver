import MySQLNIO
import FluentKit

/// Conform `MySQLError` to `DatabaseError`.
extension MySQLError: DatabaseError {
    // See `DatabaseError.isSyntaxError`.
    public var isSyntaxError: Bool {
        switch self {
            case .invalidSyntax(_):
                return true
            default:
                return false
        }
    }

    // See `DatabaseError.isConstraintFailure`.
    public var isConstraintFailure: Bool {
        switch self {
            case .duplicateEntry(_):
                return true
            default:
                return false
        }
    }

    // See `DatabaseError.isConnectionClosed`.
    public var isConnectionClosed: Bool {
        switch self {
            case .closed:
                return true
            default:
                return false
        }
    }
}
