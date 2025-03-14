//
//  IntermediatePlan.swift
//  CestrumKit
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
}
