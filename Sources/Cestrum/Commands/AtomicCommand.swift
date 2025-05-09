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
            if let manifestPath = deployment.manifestPath, manifestPath != "" {
                return [
                    "kubectl apply -f '\(manifestPath)'",
                    "kubectl scale deployment \(deployment.name) --replicas=0 -n \(dependencyGraph.namespace)",
                    "kubectl wait pods --for=delete -l app=\(deployment.name) --timeout=600s -n \(dependencyGraph.namespace)",
                    "kubectl wait deployment/\(deployment.name) --for=condition=Available=True --timeout=600s -n \(dependencyGraph.namespace)"
                ]
            } else {
                return [
                    "kubectl apply -f <MANIFEST-PATH-NOT-SPECIFIED!>",
                    "kubectl scale deployment \(deployment.name) --replicas=0 -n \(dependencyGraph.namespace)",
                    "kubectl wait pods --for=delete -l app=\(deployment.name) --timeout=600s -n \(dependencyGraph.namespace)",
                    "kubectl wait deployment/\(deployment.name) --for=condition=Available=True --timeout=600s -n \(dependencyGraph.namespace)"
                ]
            }
            
        case .remove(let deployment, let dependencyGraph):
            return [
                "kubectl delete deployment \(deployment.name) -n \(dependencyGraph.namespace)",
                "kubectl wait --for=delete deployment \(deployment.name) --timeout=600s -n \(dependencyGraph.namespace)",
                // for extra safety
                "kubectl wait pods --for=delete -l app=\(deployment.name) --timeout=600s -n \(dependencyGraph.namespace)"
            ]
        case .start(let deployment, let dependencyGraph):
            return [
                "kubectl scale deployment \(deployment.name) --replicas=1 -n \(dependencyGraph.namespace)",
                "kubectl wait pods -l app=\(deployment.name) --for=condition=Ready=True --timeout=600s -n \(dependencyGraph.namespace)"
            ]
        case .stop(let deployment, let dependencyGraph):
            return [
                "kubectl scale deployment \(deployment.name) --replicas=0 -n \(dependencyGraph.namespace)",
                // "kubectl delete pod -l app=\(deployment.name) --grace-period=0 --force -n \(dependencyGraph.namespace)",
                "kubectl wait pods --for=delete -l app=\(deployment.name) --timeout=600s -n \(dependencyGraph.namespace)"
            ]
        }
    }
    
    var doneString: String {
        switch self {
        case .add(let deployment, _):
            "added \(deployment)"
        case .remove(let deployment, _):
            "removed \(deployment)"
        case .start(let deployment, _):
            "started \(deployment)"
        case .stop(let deployment, _):
            "stopped \(deployment)"
        }
    }
    
    var beingDoneString: String {
        switch self {
        case .add(let deployment, _):
            "adding \(deployment)..."
        case .remove(let deployment, _):
            "removing \(deployment)..."
        case .start(let deployment, _):
            "starting \(deployment)..."
        case .stop(let deployment, _):
            "stopping \(deployment)..."
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
    
    public var paperValue: String {
        self.description
    }
}
