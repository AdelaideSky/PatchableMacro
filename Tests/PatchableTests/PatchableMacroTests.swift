import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(PatchableMacroMacros)
import PatchableMacroMacros

let testMacros: [String: Macro.Type] = [
    "Patchable": PatchableMacro.self,
]
#endif

final class PatchableMacroTests: XCTestCase {
    func testPatchableMacro() {
        assertMacroExpansion("""
class OtherClass: ObservableObject {
    var value: Bool = false
    enum CodingKeys: String, CodingKey {
        case value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }
    
    required init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = try container.decode(type(of: self.value), forKey: .value)
    }
    init() {}
}

@Patchable
class TestClass: ObservableObject {
    @Published var value: Bool = false { didSet {
        print("e")
    }}
    @patchableChild var test: OtherClass = .init()

    enum CodingKeys: String, CodingKey {
        case value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }
    
    required init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = try container.decode(type(of: self.value), forKey: .value)
    }
}
""", expandedSource: """
class TestClass: ObservableObject {
    @Published var value: Bool = false { didSet {
        print("e")
    }}

    enum CodingKeys: String, CodingKey {
        case value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }
    
    required init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = try container.decode(type(of: self.value), forKey: .value)
    }
}

extension TestClass: Patchable {
}
""", macros: testMacros)
    }
}
