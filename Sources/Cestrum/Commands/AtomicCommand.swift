//
//  AtomicCommand.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

/// Represents an instruction that can be run.
public enum AtomicCommand: Command, Hashable {
    case add(Deployment, DependencyGraph)
    case remove(Deployment, DependencyGraph)
    case start(Deployment, DependencyGraph)
    case stop(Deployment, DependencyGraph)
    
    var kubernetesEquivalent: [String] {
        switch self {
        case .add(let deployment, let dependencyGraph):
            return [
                "kubectl apply -f some/path/to/manifest.yaml",
                "kubectl scale deployment \(deployment.name) --replicas=0 -n \(dependencyGraph.namespace)"
            ]
        case .remove(let deployment, let dependencyGraph):
            return ["kubectl delete deployment \(deployment.name) -n \(dependencyGraph.namespace)"]
        case .start(let deployment, let dependencyGraph):
            return ["kubectl scale deployment \(deployment.name) --replicas=1 -n \(dependencyGraph.namespace)"]
        case .stop(let deployment, let dependencyGraph):
            return [
                "kubectl scale deployment client --replicas=0 -n \(dependencyGraph.namespace)",
                "kubectl delete pod -l app=\(deployment.name) --grace-period=0 --force -n \(dependencyGraph.namespace)"
            ]
        }
    }
    
    public var description: String {
        switch self {
        case .add(let deployment, _):
            "add \(deployment)"
        case .remove(let deployment, _):
            "remove \(deployment)"
        case .start(let deployment, _):
            "start \(deployment)"
        case .stop(let deployment, _):
            "stop \(deployment)"
        }
    }
}
