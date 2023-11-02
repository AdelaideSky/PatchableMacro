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
        
        // check if codingkeys are cudtomised
        let enums = classDecl.memberBlock.members.compactMap { $0.decl.as(EnumDeclSyntax.self) }
        
        let codingKeysEnum = enums.first(where: {$0.name.text == "CodingKeys"})
        
        let ceodingKeys = codingKeysEnum?.memberBlock.members.compactMap { member in
            
        }
        
        var codingKeys: [String: String] = [:]
        
        for member in codingKeysEnum?.memberBlock.members ?? [] {
            let theCase = member.decl.as(EnumCaseDeclSyntax.self)?.elements.first?.as(EnumCaseElementSyntax.self)
            let key = theCase?.name.text
            let rawVal = theCase?.rawValue?.as(InitializerClauseSyntax.self)?.value.as(StringLiteralExprSyntax.self)?.segments.as(StringLiteralSegmentListSyntax.self)?.first?.as(StringSegmentSyntax.self)?.content.text
            if let key = key {
                if let rawVal = rawVal {
                    codingKeys[key] = rawVal
                } else {
                    codingKeys[key] = key
                }
            }
            
        }
        
        
        //else, use variables
        let variables = classDecl.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        
        let labels = variables.compactMap { variable in
            let varLabel = variable.bindings.first?.as(PatternBindingSyntax.self)?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            let decorator = variable.attributes.first?.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text
            if let varLabel = varLabel {
                return (varLabel, codingKeys[varLabel] ?? varLabel, decorator ?? "")
            }
            return nil
        }
        
        var patch = try FunctionDeclSyntax("func patch(_ key: String, with value: Data) throws") {
            try SwitchExprSyntax("switch key") {
                for label in labels {
                    if label.2 == "GoXLRValue" {
                        SwitchCaseSyntax(
                                """
                                case "\(raw: label.1)":
                                    self._\(raw: label.0).freeValue = try JSONDecoder().decode(type(of: self.\(raw: label.0)), from: value)
                                """
                        )
                    } else {
                        SwitchCaseSyntax(
                                """
                                case "\(raw: label.1)":
                                    self.\(raw: label.0) = try JSONDecoder().decode(type(of: self.\(raw: label.0)), from: value)
                                """
                        )
                    }
                    
                }
                SwitchCaseSyntax("default: throw Patchable.PatchError.noValueForKey")
            }
        }
        let elligibleValues = labels.filter({$0.2 == "PatchableChild"})
        
        var childPatch = try FunctionDeclSyntax("func patch(child: String, path: [String], with value: Data) throws") {
            if !elligibleValues.isEmpty {
                try SwitchExprSyntax("switch child") {
                        for element in elligibleValues {
                            SwitchCaseSyntax(
                                """
                                case "\(raw: element.1)":
                                    try self.\(raw: element.0).patch(path, with: value)
                                """
                            )
                        }
                        SwitchCaseSyntax("default: throw Patchable.PatchError.noValueForKey")
                    }
            }
        }
        return [.init(patch), .init(childPatch)]
    }
    
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, 
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        
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