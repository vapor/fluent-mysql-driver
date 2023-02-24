import MySQLNIO
import FluentKit

extension MySQLError: DatabaseError {
    public var isSyntaxError: Bool {
        switch self {
            case .invalidSyntax(_):
                return true
            default:
                return false
        }
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
        switch self {
            case .closed:
                return true
            default:
                return false
        }
    }
}
