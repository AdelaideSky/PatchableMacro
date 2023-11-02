//
//  File.swift
//  
//
//  Created by Adélaïde Sky on 02/11/2023.
//

import Foundation
import SwiftUI

extension Dictionary: PatchableProtocol where Key == String, Value: PatchableProtocol {
    public func patch(_ key: String, with value: Data) throws {}
    
    public func patch(child: String, path: [String], with value: Data) throws {
        try self[child]?.patch(path, with: value)
    }
}

extension Array: PatchableProtocol where Element: PatchableProtocol {
    public func patch(_ key: String, with value: Data) throws {}
    
    public func patch(child: String, path: [String], with value: Data) throws {
        if let index = Int(child) {
            guard index < self.count else { return }
            
            try self[index].patch(path, with: value)
        } else {
            return
        }
        
    }
}
//IM GONNA BREAK SOEMTHING YOU CAN'T FUCKING JUST HAVE 2 CONDITIONAL COMFORMANCE HELP AND ITS BEEN 1H I TRY TO FUCKING FIGURE THIS OUT SO HERE YOU GO YOU WON'T HAVE THE OPTION OK

//
//extension Dictionary: PatchableProtocol where Key == String {
//    public func patch(_ key: String, with value: Data) throws {
//        
//    }
//    
//    public func patch(child: String, path: [String], with value: Data) throws {}
//}
//
