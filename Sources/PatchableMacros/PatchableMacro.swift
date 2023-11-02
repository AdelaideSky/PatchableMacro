import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftUI

public struct PatchableMacro: ExtensionMacro, MemberMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else { return [] }
        let enums = classDecl.memberBlock.members.compactMap { $0.decl.as(EnumDeclSyntax.self) }
        
        guard let codingKeysEnum = enums.first(where: {$0.name.text == "CodingKeys"}) else {
            print("No codingKeys !")
            return []
        }
        let codingKeys = codingKeysEnum.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements.first?.name.text }
        let variables = classDecl.memberBlock.members.compactMap({ $0.decl.as(VariableDeclSyntax.self)})
        
        var patch = try FunctionDeclSyntax("func patch(_ key: CodingKeys, with value: Data) throws") {
            try SwitchExprSyntax("switch key") {
                    for element in codingKeys {
                        if let variable = variables.first(where: {$0.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == element}) {
                            if variable.attributes.first?.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "GoXLRValue" {
                                SwitchCaseSyntax(
                                    """
                                    case .\(raw: element):
                                        self._\(raw: element).freeValue = try JSONDecoder().decode(type(of: self.\(raw: element)), from: value)
                                    """
                                )
                            } else {
                                SwitchCaseSyntax(
                                    """
                                    case .\(raw: element):
                                        self.\(raw: element) = try JSONDecoder().decode(type(of: self.\(raw: element)), from: value)
                                    """
                                )
                            }
                        }
                        
                    }
                }
        }
        
        let elligibleValues = classDecl.memberBlock.members.compactMap { thing in
            if let value = thing.decl.as(VariableDeclSyntax.self) {
                if value.attributes.first?.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "PatchableChild" {
                    return value.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                }
            }
            return nil
        }
        
        var childPatch = try FunctionDeclSyntax("func patch(child: CodingKeys, path: [String], with value: Data) throws") {
            if !elligibleValues.isEmpty {
                try SwitchExprSyntax("switch child") {
                        for element in elligibleValues {
                            SwitchCaseSyntax(
                                """
                                case .\(raw: element):
                                    try self.\(raw: element).patch(path, with: value)
                                """
                            )
                        }
                        SwitchCaseSyntax("default: return")
                    }
            }
        }
        return [.init(patch), .init(childPatch)]
    }
    
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else { return [] }
        let enums = classDecl.memberBlock.members.compactMap { $0.decl.as(EnumDeclSyntax.self) }
        
        guard let codingKeysEnum = enums.first(where: {$0.name.text == "CodingKeys"}) else {
            print("No codingKeys !")
            return []
        }
        
        let sendableExtension = try ExtensionDeclSyntax("extension \(type.trimmed): PatchableProtocol") { }
        
        guard let extensionDecl = sendableExtension.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDecl]
    }
}

@main
struct PatchableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PatchableMacro.self,
    ]
}
