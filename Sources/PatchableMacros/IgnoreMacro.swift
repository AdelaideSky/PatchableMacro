//
//  File.swift
//  
//
//  Created by Adélaïde Sky on 06/11/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros


public struct IgnoreMacro: PeerMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
