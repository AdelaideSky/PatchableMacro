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
    associatedtype CodingKeys: CodingKey, RawRepresentable where CodingKeys.RawValue: StringProtocol
    
    func patch(_ key: CodingKeys, with value: Data) throws
    func patch(child: CodingKeys, path: [String], with value: Data) throws
}

public extension PatchableProtocol {
    func patch(_ path: [String], with value: Data) throws {
        guard !path.isEmpty else { return }
        
        if path.count == 1 {
            if let key = CodingKeys(stringValue: path.first ?? "") {
                try self.patch(key, with: value)
            }
        } else {
            if let key = CodingKeys(stringValue: path.first!) {
                try self.patch(child: key, path: Array(path.dropFirst()), with: value)
            }
        }
    }
}
