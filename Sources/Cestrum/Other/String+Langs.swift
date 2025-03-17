//
//  String+Langs.swift
//  Cestrum
//
//  Created by Wadÿe on 13/03/2025.
//

import Foundation

extension String {
    var isValidVariableName: Bool {
        // Check if the string is empty
        guard !self.isEmpty else { return false }
        
        if self == "_" {
            return false
        }

        // Ensure it doesn't start with a number
        if self.first?.isNumber == true {
            return false
        }

        // Ensure it contains only letters, numbers, and underscores
        let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if self.rangeOfCharacter(from: validCharacterSet.inverted) != nil {
            return false
        }

        return true
    }
}
