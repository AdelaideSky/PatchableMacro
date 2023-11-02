//
//  File.swift
//  
//
//  Created by Adélaïde Sky on 02/11/2023.
//

import SwiftSyntax
import SwiftSyntaxMacros


public struct ChildMacro: PeerMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
