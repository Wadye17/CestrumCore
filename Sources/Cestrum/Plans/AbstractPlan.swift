//
//  AbstractPlan.swift
//  Cestrum
//
//  Created by Wadÿe on 12/03/2025.
//

import Foundation

public struct AbstractPlan: Plan, ExpressibleByArrayLiteral {
    typealias Content = AbstractCommand
    public internal(set) var lines: [AbstractCommand]
    
    public init() {
        self.lines = []
    }
    
    public init(with lines: [AbstractCommand]) {
        self.lines = lines
    }
    
    init(@AbstractPlanBuilder _ lines: () -> [AbstractCommand]) {
        self.lines = lines()
    }
    
    public init(arrayLiteral elements: AbstractCommand...) {
        self.lines = elements
    }
    
    public static func generate(from code: String) -> (graphName: String, abstractPlan: AbstractPlan) {
        return CESPInterpreter.interpret(code: code)
    }
    
    public var description: String {
        self.lines.map({ $0.description }).joined(separator: "\n")
    }
}

@resultBuilder
struct AbstractPlanBuilder {
    static func buildBlock(_ components: AbstractCommand...) -> [AbstractCommand] {
        return components
    }
}
