//
//  IntermediatePlan.swift
//  Cestrum
//
//  Created by Wadÿe on 12/03/2025.
//

import Foundation

public struct IntermediatePlan: Plan {
    typealias Content = IntermediateCommand
    
    public internal(set) var lines: [IntermediateCommand]
    
    init() {
        self.lines = []
    }
    
    public var description: String {
        self.lines.map({ $0.description }).joined(separator: "\n")
    }
}
