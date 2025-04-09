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
    
    func createTarget(on graph: DependencyGraph) -> DependencyGraph {
        let targetGraph = graph.createCopy()
        for line in lines {
            line.reflect(considering: targetGraph)
        }
        guard !targetGraph.hasCycles else {
            fatalError("Fatal error: Target graph of '\(graph.namespace)' contains at least one cycle.\n\(targetGraph)")
        }
        return targetGraph
    }
    
    public var isTransparent: Bool {
        for line in lines {
            guard line.isTransparent else { return false }
            return true
        }
        return true
    }
    
    public var isEmpty: Bool {
        self.lines.isEmpty
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
