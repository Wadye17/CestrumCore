//
//  ConcretePlan.swift
//  Cestrum
//
//  Created by Wadÿe on 12/03/2025.
//

import Foundation
import Collections

public final class ConcretePlan: OperationCollection {
    typealias Content = ConcreteOperation
    
    public internal(set) var lines: OrderedSet<ConcreteOperation>
    let initialGraph: DependencyGraph
    var targetGraph: DependencyGraph
    var hasAlreadyBeenApplied: Bool = false
    
    init(from initialGraph: DependencyGraph, to targetGraph: DependencyGraph) {
        self.lines = []
        self.initialGraph = initialGraph.createCopy() // stores only a copy of the initial graph, not the graph itself.
        self.targetGraph = targetGraph
        self.synchronise()
    }
    
    internal func synchronise() {
        let intermediateGraph = initialGraph.createCopy()
        
        var stopActions: Array<ConcreteOperation> = []
        var removeActions: Set<ConcreteOperation> = []
        var addActions: Set<ConcreteOperation> = []
        var startActions: Array<ConcreteOperation> = []
        
        // deployments present in the initial graph, but missing in the target graph.
        let deploymentsToRemove = intermediateGraph.deployments.subtracting(targetGraph.deployments)
        
        // perform removal operations first (AFTER stopping the necessary deployments)
        for deployment in deploymentsToRemove {
            let actualDeployment = intermediateGraph.checkPresence(of: deployment)
            actualDeployment.stop(considering: intermediateGraph, atomicPlan: &stopActions)
            intermediateGraph.removeDeployment(actualDeployment, applied: false)
            removeActions.insert(.remove(actualDeployment, intermediateGraph))
        }
        self.lines.append(contentsOf: stopActions)
        self.lines.append(contentsOf: removeActions)
        
        // deployments present in the target graph but missing from the initial graph.
        let deploymentsToAdd = targetGraph.deployments.subtracting(initialGraph.deployments)
        
        // perform addition operations
        for deployment in deploymentsToAdd {
            intermediateGraph.add(deployment, requirementsNames: [], applied: false)
            addActions.insert(.add(deployment, intermediateGraph))
        }
        
        // syncing dependencies with those newly added
        for deployment in deploymentsToAdd {
            let actualDeployment = intermediateGraph.checkPresence(of: deployment)
            let requirements = targetGraph.getRequirements(ofDeploymentNamed: deployment.name)
            let requirers = targetGraph.getRequirers(ofDeploymentNamed: deployment.name)
            for requirement in requirements {
                let actualRequirement = intermediateGraph.checkPresence(of: requirement)
                intermediateGraph.add(actualDeployment --> actualRequirement)
            }
            for requirer in requirers {
                let actualRequirer = intermediateGraph.checkPresence(of: requirer)
                intermediateGraph.add(actualRequirer --> actualDeployment)
            }
        }
        
        // syncing all dependencies (even those newly introduced)
        intermediateGraph.dependencies = targetGraph.dependencies
        
        intermediateGraph.fatalCheckForCycles()
        
        // startup operations of those left unstarted (those who no longer depend on others.)
        for deployment in intermediateGraph.deployments where deployment.status == .stopped {
            deployment.start(considering: intermediateGraph, atomicPlan: &startActions)
        }
        
        self.lines.append(contentsOf: addActions)
        self.lines.append(contentsOf: startActions)
    }
    
    /// The K8s command equivalent this concrete plan.
    public var kubernetesEquivalent: [String] {
        var result = [String]()
        for line in lines {
            let lineKubernetesEquivalent = line.kubernetesEquivalent
            result.append(contentsOf: lineKubernetesEquivalent)
        }
        return result
    }
    
    /// Applies this reconfiguration plan.
    public func apply(on graph: DependencyGraph, onKubernetes: Bool = true, stdout: FileHandle? = .standardOutput, stderr: FileHandle? = .standardError) {
        if onKubernetes {
            for line in self.lines {
                let fullComposedCommand = line.kubernetesEquivalent.joined(separator: " && ")
                print("\(line.beingDoneString)")
                runCommand(fullComposedCommand, stdout: stdout, stderr: stderr)
                print("\(line.doneString)")
            }
        }
        
        graph.deployments = targetGraph.deployments
        graph.dependencies = targetGraph.dependencies
    }
    
    public var description: String {
        self.lines.map({ $0.description }).joined(separator: "\n")
    }
}
