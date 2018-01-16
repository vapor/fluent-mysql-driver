import Foundation


public enum DefaultValue {
    case none
    case null
    case string(String)
    case int(Int)
    case float(Float)
    case double(Double)
    case currentTimestamp
    
    var attribute: String? {
        switch self {
        case .null:
            return "DEFAULT NULL"
        case .string(let string):
            return "DEFAULT '\(string)'"
        case .int(let int):
            return "DEFAULT '\(int)'"
        case .float(let float):
            return "DEFAULT '\(float)'"
        case .double(let double):
            return "DEFAULT '\(double)'"
        case .currentTimestamp:
            return "DEFAULT CURRENT_TIMESTAMP"
        default:
            return nil
        }
    }
}
