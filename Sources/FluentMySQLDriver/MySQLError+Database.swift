import FluentKit
import MySQLNIO

/// Conform `MySQLError` to `DatabaseError`.
extension MySQLNIO.MySQLError: FluentKit.DatabaseError {
    // See `DatabaseError.isSyntaxError`.
    public var isSyntaxError: Bool {
        switch self {
        case .invalidSyntax(_):
            true
        default:
            false
        }
    }

    // See `DatabaseError.isConstraintFailure`.
    public var isConstraintFailure: Bool {
        switch self {
        case .duplicateEntry(_):
            true
        default:
            false
        }
    }

    // See `DatabaseError.isConnectionClosed`.
    public var isConnectionClosed: Bool {
        switch self {
        case .closed:
            true
        default:
            false
        }
    }
}
