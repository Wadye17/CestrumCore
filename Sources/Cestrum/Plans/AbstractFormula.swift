//
//  AbstractFormula.swift
//  Cestrum
//
//  Created by Wadÿe on 12/03/2025.
//

import Foundation
import Collections

public struct AbstractFormula: OperationCollection, ExpressibleByArrayLiteral {
    typealias Content = AbstractOperation
    public internal(set) var lines: OrderedSet<AbstractOperation>
    
    public init() {
        self.lines = []
    }
    
    public init(with lines: OrderedSet<AbstractOperation>) {
        self.lines = lines
    }
    
    init(@AbstractPlanBuilder _ lines: () -> OrderedSet<AbstractOperation>) {
        self.lines = lines()
    }
    
    public init(arrayLiteral elements: AbstractOperation...) {
        self.lines = OrderedSet(elements)
    }
    
    func createTargetGraph(from graph: DependencyGraph) throws(RuntimeError) -> DependencyGraph {
        let targetGraph = graph.createCopy()
        for line in lines {
            try line.reflect(on: targetGraph)
        }
        guard !targetGraph.hasCycles else {
            throw RuntimeError.targetConfigurationGraphContainsCycles(configuration: graph.namespace)
        }
        return targetGraph
    }
    
    func createTargetGraphWithComplementaryInformation(from graph: DependencyGraph) throws(RuntimeError) -> (DependencyGraph, Set<ComplementaryInformation>) {
        let targetGraph = try createTargetGraph(from: graph)
        var complementaryInformation = Set<ComplementaryInformation>()
        for line in lines {
            if case .replace(let oldDeploymentName, let newDeployment) = line {
                complementaryInformation.insert(.replacement(oldDeployment: oldDeploymentName, newDeployment: newDeployment.name))
            }
        }
        return (targetGraph, complementaryInformation)
    }
    
    public var isTransparent: Bool {
        for line in lines {
            guard line.isTransparent else { return false }
            continue
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
    static func buildBlock(_ components: AbstractOperation...) -> [AbstractOperation] {
        return components
    }
}
