import SwiftUI

@attached(extension, conformances: PatchableProtocol)
@attached(member, names: named(patch))
public macro Patchable() = #externalMacro(module: "PatchableMacros", type: "PatchableMacro")

@attached(peer)
public macro child() = #externalMacro(module: "PatchableMacros", type: "ChildMacro")

@attached(peer)
public macro IgnorePatches() = #externalMacro(module: "PatchableMacros", type: "IgnoreMacro")

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
    case noValueForKey([String])
    
}
extension PatchError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noValueForKey(let path):
            return "No value for key: \(path.first ?? "Unknown"), remaining path: \(String(describing: path.dropFirst))"
        }
    }
}
