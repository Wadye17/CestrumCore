//
//  AbstractCommand.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

public enum AbstractCommand: Command {
    case add(Deployment, requirements: Set<String>)
    case remove(String)
    case replace(oldDeploymentName: String, newDeployment: Deployment)
    case bind(deploymentName: String, requirementsNames: Set<String>)
    case release(deploymentName: String, otherDeploymentsNames: Set<String>)
    
    public func reflect(considering graph: DependencyGraph) {
        switch self {
        case .add(let deployment, let requirements):
            graph.add(deployment, requirementsNames: requirements, applied: false)
        case .remove(let deploymentName):
            graph.removeDeployment(named: deploymentName, applied: false)
        case .replace(let oldDeploymentName, let newDeployment):
            let archivedDeployment = ArchivedDeployment(forDeploymentNamed: oldDeploymentName, in: graph)
            graph.removeDeployment(named: oldDeploymentName, applied: false)
            graph.add(newDeployment, requirementsNames: archivedDeployment.requirements, applied: false)
            for requirer in archivedDeployment.requirers {
                graph.add(requirer --> newDeployment.name)
            }
        case .bind(let deploymentName, let requirmentsNames):
            graph.bindDeployment(named: deploymentName, toDeploymentsNamed: requirmentsNames)
        case .release(let deploymentName, let otherDeploymentNames):
            graph.unbindDeployment(name: deploymentName, fromDeploymentsNamed: otherDeploymentNames)
        }
    }
    
    public var description: String {
        switch self {
        case .add(let deployment, let requirements):
            "add \(deployment) requiring {\(requirements.joined(separator: ", "))}"
        case .remove(let deployment):
            "remove \(deployment)"
        case .replace(let oldDeployment, let newDeployment):
            "replace \(oldDeployment) with \(newDeployment)"
        case .bind(let deploymentName, let requirementsNames):
            "bind \(deploymentName) to {\(requirementsNames.joined(separator: ", "))}"
        case .release(let deploymentName, let otherDeploymentsNames):
            "release \(deploymentName) from {\(otherDeploymentsNames.joined(separator: ", "))}"
        }
    }
}
