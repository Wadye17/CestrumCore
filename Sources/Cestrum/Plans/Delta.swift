//
//  Delta.swift
//  CestrumCore
//
//  Created by Wadÿe on 17/09/2025.
//

import Foundation

/// Captures the difference between a source graph and a target graph, and calculates the deployments to stop and the deployments to start.
public struct Delta {
    let sourceGraph: DependencyGraph
    let targetGraph: DependencyGraph
    let deploymentsToStop: Set<Deployment>
    let deploymentsToRemove: Set<Deployment>
    let deploymentsToAdd: Set<Deployment>
    let deploymentsToStart: Set<Deployment>
    let complementaryInformation: Set<ComplementaryInformation>?
    
    /// Initialises a new delta value.
    init(sourceGraph: DependencyGraph, targetGraph: DependencyGraph, complementaryInformation: Set<ComplementaryInformation>? = nil) {
        // i.e., the deployments present in the target graph but missing from the source graph.
        let deploymentsToAdd = targetGraph.deployments.subtracting(sourceGraph.deployments)
        
        // i.e., the deployments present in the source graph but missing from the target graph.
        let deploymentsToRemove = sourceGraph.deployments.subtracting(targetGraph.deployments)
        
        var allTransitiveRequirersForStopping = Set<Deployment>()
        
        for deploymentToRemove in deploymentsToRemove {
            allTransitiveRequirersForStopping.formUnion(deploymentToRemove.globalRequirers(in: sourceGraph))
        }
        
        // the deployments to remove, along with their transitive requirers
        let deploymentsToStop = deploymentsToRemove.union(allTransitiveRequirersForStopping)
        
        var allTransitiveRequirersForStarting = Set<Deployment>()
        let deploymentsAwaitingRestart = deploymentsToStop.subtracting(deploymentsToRemove)
        for deploymentToAdd in deploymentsToAdd {
            allTransitiveRequirersForStarting.formUnion(deploymentToAdd.globalRequirers(in: targetGraph))
        }
        for deploymentAwaitingRestart in deploymentsAwaitingRestart {
            allTransitiveRequirersForStarting.formUnion(
                deploymentAwaitingRestart.globalRequirers(in: targetGraph)
            )
        }
        
        // the deployments that have not been removed, but are stopped.
        // + the deployments that will be added
        // + the transitive requirers that were previously stopped, or the transitive requirers
        // of the new deployments
        let deploymentsToStart = deploymentsAwaitingRestart
            .union(deploymentsToAdd)
            .union(allTransitiveRequirersForStarting)
        
        self.sourceGraph = sourceGraph
        self.targetGraph = targetGraph
        self.deploymentsToStop = deploymentsToStop
        self.deploymentsToRemove = deploymentsToRemove
        self.deploymentsToAdd = deploymentsToAdd
        self.deploymentsToStart = deploymentsToStart
        self.complementaryInformation = complementaryInformation
    }
}

extension Delta {
    var allDeployments: Set<Deployment> {
        deploymentsToStop.union(deploymentsToRemove).union(deploymentsToAdd).union(deploymentsToStart)
    }
    
    func extractNodesAndFlows(constraints: OrderingConstraintSet) -> (nodes: NodeSet, naiveFlows: FlowSet) {
        let nodes = NodeSet()
            .union(self.deploymentsToStop.map { Node(.task(.stop($0, self.sourceGraph))) })
            .union(self.deploymentsToRemove.map { Node(.task(.remove($0, self.sourceGraph))) })
            .union(self.deploymentsToAdd.map { Node(.task(.add($0, self.targetGraph))) })
            .union(self.deploymentsToStart.map { Node(.task(.start($0, self.targetGraph))) })
        
        print(nodes)
        
        var naiveFlows = FlowSet()
        
        for constraint in constraints {
            naiveFlows.insert(
                Flow(
                    source: nodes.task(having: constraint.source)!,
                    target: nodes.task(having: constraint.target)!
                )
            )
        }
        
        return (nodes, naiveFlows)
    }
}
