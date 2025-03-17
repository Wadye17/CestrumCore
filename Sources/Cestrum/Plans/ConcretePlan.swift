//
//  ConcretePlan.swift
//  Cestrum
//
//  Created by Wadÿe on 12/03/2025.
//

import Foundation

public final class ConcretePlan: Plan {
    typealias Content = AtomicCommand
    
    public internal(set) var lines: [AtomicCommand]
    let initialGraph: DependencyGraph
    var targetGraph: DependencyGraph? = nil
    
    init(initialGraph: DependencyGraph) {
        self.lines = []
        self.initialGraph = initialGraph
    }
    
    /// Applies the given instruction
    public func apply(on graph: DependencyGraph, onKubernetes: Bool = true) {
        if onKubernetes {
            for line in lines {
                for command in line.kubernetesEquivalent {
                    runCommand(command)
                }
                if case AtomicCommand.stop(_, _) = line {
                    // breathe a bit after a stop command (for observability)
                    do { sleep(5) }
                }
            }
        }
        
        guard let targetGraph else {
            fatalError("Cannot apply plan because no target graph was set; this should not happen.")
        }
        
        graph.nodes = targetGraph.nodes
        graph.arcs = targetGraph.arcs
    }
}
