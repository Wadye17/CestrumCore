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
    var targetGraph: DependencyGraph
    
    init(from initialGraph: DependencyGraph, to targetGraph: DependencyGraph) {
        self.lines = []
        self.initialGraph = initialGraph.createCopy() // stores only a copy of the initial graph, not the graph itself.
        self.targetGraph = targetGraph
        self.synchronise()
    }
    
    internal func synchronise() {
        let intermediateGraph = initialGraph.createCopy()
        
        var stopActions: Array<AtomicCommand> = []
        var removeActions: Set<AtomicCommand> = []
        var addActions: Set<AtomicCommand> = []
        var startActions: Array<AtomicCommand> = []
        
        // deployments present in the initial graph, but missing in the target graph.
        let deploymentsToRemove = intermediateGraph.nodes.subtracting(targetGraph.nodes)
        
        // perform removal operations first (AFTER stopping the necessary deployments)
        for deployment in deploymentsToRemove {
            let actualDeployment = intermediateGraph.checkPresence(of: deployment)
            actualDeployment.stop(considering: intermediateGraph, atomicPlan: &stopActions)
            intermediateGraph.remove(actualDeployment, applied: false)
            removeActions.insert(.remove(actualDeployment, intermediateGraph))
        }
        self.lines.append(contentsOf: stopActions)
        self.lines.append(contentsOf: removeActions)
        
        // deployments present in the target graph but missing from the initial graph.
        let deploymentsToAdd = targetGraph.nodes.subtracting(initialGraph.nodes)
        
        // perform addition operations
        for deployment in deploymentsToAdd {
            intermediateGraph.add(deployment, requirements: [], applied: false)
            addActions.insert(.add(deployment, intermediateGraph))
        }
        
        // syncing dependencies
        for deployment in deploymentsToAdd {
            let actualDeployment = intermediateGraph.checkPresence(of: deployment)
            let requirements = targetGraph.getRequirements(of: deployment)
            let requirers = targetGraph.getRequirers(of: deployment)
            for requirement in requirements {
                let actualRequirement = intermediateGraph.checkPresence(of: requirement)
                intermediateGraph.add(actualDeployment --> actualRequirement)
            }
            for requirer in requirers {
                let actualRequirer = intermediateGraph.checkPresence(of: requirer)
                intermediateGraph.add(actualRequirer --> actualDeployment)
            }
        }
        
        // startup operations of those left unstarted (those who no longer depend on others.)
        for deployment in intermediateGraph.nodes where deployment.status == .stopped {
            deployment.start(considering: intermediateGraph, atomicPlan: &startActions)
        }
        
        self.lines.append(contentsOf: addActions)
        self.lines.append(contentsOf: startActions)
    }
    
    public var kubernetesEquivalent: [String] {
        var result = [String]()
        for line in lines {
            let lineKubernetesEquivalent = line.kubernetesEquivalent
            result.append(contentsOf: lineKubernetesEquivalent)
        }
        return result
    }
    
    public func apply(on graph: DependencyGraph, onKubernetes: Bool = true, stdout: FileHandle? = .standardOutput, stderr: FileHandle? = .standardError, timeInterval: UInt32 = 3) {
        if onKubernetes {
            for line in lines {
                for command in line.kubernetesEquivalent {
                    runCommand(command)
                    do { sleep(timeInterval) }
                }
                print("[Cestrum]: \(line.doneString)")
            }
        }
        
        graph.nodes = targetGraph.nodes
        graph.arcs = targetGraph.arcs
    }
    
    public var description: String {
        self.lines.map({ $0.description }).joined(separator: "\n")
    }
}
