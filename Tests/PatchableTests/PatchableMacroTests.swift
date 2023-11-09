import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(PatchableMacros)
import PatchableMacros

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
        case value = "TheValue"
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
    @child 
    @Published var test: OtherClass? = .init()

    @Published var effectFX: String = ""

    private enum CodingKeys: String, CodingKey {
        case value = "TheValue"
        case test
        case bleep = "Bleep"
        case cough = "Cough"
        case effectFX = "EffectFx"
        case effectHardTune = "EffectHardTune"
        case effectMegaphone = "EffectMegaphone"
        case effectRobot = "EffectRobot"
        case effectSelect1 = "EffectSelect1"
        case effectSelect2 = "EffectSelect2"
        case effectSelect3 = "EffectSelect3"
        case effectSelect4 = "EffectSelect4"
        case effectSelect5 = "EffectSelect5"
        case effectSelect6 = "EffectSelect6"
        case fader1Mute = "Fader1Mute"
        case fader2Mute = "Fader2Mute"
        case fader3Mute = "Fader3Mute"
        case fader4Mute = "Fader4Mute"
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
