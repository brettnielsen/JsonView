import Foundation

extension Array {
    var nilIfEmpty: [Element]? {
        isEmpty ? nil : self
    }
}
