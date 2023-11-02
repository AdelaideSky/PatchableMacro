import SwiftUI

@attached(extension, conformances: PatchableProtocol)
@attached(member, names: named(patch))
public macro Patchable() = #externalMacro(module: "PatchableMacros", type: "PatchableMacro")

@propertyWrapper public struct PatchableChild<Value: PatchableProtocol> {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

public protocol PatchableProtocol: Codable {
    func patch(_ key: String, with value: Data) throws
    func patch(child: String, path: [String], with value: Data) throws
}

public extension PatchableProtocol {
    func patch(_ path: [String], with value: Data) throws {
        guard !path.isEmpty else { return }
        
        if path.count == 1 {
            if let key = path.first {
                try self.patch(key, with: value)
            }
        } else {
            if let key = path.first {
                try self.patch(child: key, path: Array(path.dropFirst()), with: value)
            }
        }
    }
}

public enum PatchError: Error {
    case noValueForKey
    
}