import SwiftUI

struct JSONNode: Identifiable, Hashable {
    let id = UUID()
    let key: String?
    let value: JSONValue
    var children: [JSONNode]
    let path: [String]
    let pathString: String
    
    init(key: String?, value: JSONValue, children: [JSONNode], path: [String]) {
        self.key = key
        self.value = value
        self.children = children
        self.path = path
        self.pathString = path.joined(separator: ".")
    }
    
    static func == (lhs: JSONNode, rhs: JSONNode) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var displayKey: String {
        key ?? ""
    }
    
    var displayValue: String {
        switch value {
        case .string(let s): return "\"\(s)\""
        case .number(let n): return "\(n)"
        case .bool(let b): return b ? "true" : "false"
        case .null: return "null"
        case .array: return "[\(children.count) items]"
        case .object: return "{\(children.count) keys}"
        }
    }
    
    var icon: String {
        switch value {
        case .string: return "textformat.abc"
        case .number: return "number"
        case .bool: return "checkmark.circle"
        case .null: return "circle.slash"
        case .array: return "square.stack"
        case .object: return "folder"
        }
    }
    
    var valueColor: Color {
        switch value {
        case .string: return .green
        case .number: return .blue
        case .bool: return .orange
        case .null: return .gray
        case .array, .object: return .secondary
        }
    }
}

enum JSONValue {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array
    case object
}
