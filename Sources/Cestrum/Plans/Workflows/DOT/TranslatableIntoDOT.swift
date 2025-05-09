//
//  TranslatableIntoDOT.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

/// A type that has an equivalent translation in the DOT language.
protocol TranslatableIntoDOT {
    /// The DOT translation of the instance.
    var dotTranslation: String { get }
}

extension String {
    func addingNewLine(_ content: Self, indented: Bool = true) -> Self {
        self.appending("\n\(indented ? "\t" : "")\(content)")
    }
    
    mutating func addNewLine(_ content: Self, indented: Bool = true) {
        self.append("\n\(indented ? "\t" : "")\(content)")
    }
}
