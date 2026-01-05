import Foundation

class JSONParser {
    static func parse(_ data: Data) throws -> [JSONNode] {
        let json = try JSONSerialization.jsonObject(with: data)
        return [nodeFrom(value: json, key: "root", path: [])]
    }
    
    static func nodeFrom(value: Any, key: String?, path: [String]) -> JSONNode {
        let currentPath = key.map { path + [$0] } ?? path
        
        switch value {
        case let str as String:
            return JSONNode(key: key, value: .string(str), children: [], path: currentPath)
        case let num as NSNumber:
            if CFBooleanGetTypeID() == CFGetTypeID(num) {
                return JSONNode(key: key, value: .bool(num.boolValue), children: [], path: currentPath)
            }
            return JSONNode(key: key, value: .number(num.doubleValue), children: [], path: currentPath)
        case let arr as [Any]:
            let children = arr.enumerated().map { nodeFrom(value: $1, key: "[\($0)]", path: currentPath) }
            return JSONNode(key: key, value: .array, children: children, path: currentPath)
        case let dict as [String: Any]:
            let children = dict.sorted { $0.key < $1.key }.map { nodeFrom(value: $1, key: $0, path: currentPath) }
            return JSONNode(key: key, value: .object, children: children, path: currentPath)
        case is NSNull:
            return JSONNode(key: key, value: .null, children: [], path: currentPath)
        default:
            return JSONNode(key: key, value: .null, children: [], path: currentPath)
        }
    }
}
