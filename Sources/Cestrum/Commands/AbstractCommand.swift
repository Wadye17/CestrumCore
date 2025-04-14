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
    
    func reflect(on graph: DependencyGraph) throws(RuntimeError) {
        switch self {
        case .add(let deployment, let requirements):
            for requirementName in requirements {
                guard graph[requirementName] != nil else {
                    throw RuntimeError.requirementNotFound(name: requirementName, configuration: graph.namespace)
                }
            }
            graph.add(deployment, requirementsNames: requirements, applied: false)
        case .remove(let deploymentName):
            guard let deployment = graph[deploymentName] else {
                throw RuntimeError.deploymentToRemoveNotFound(name: deploymentName, configuration: graph.namespace)
            }
            graph.removeDeployment(named: deploymentName, applied: false)
        case .replace(let oldDeploymentName, let newDeployment):
            guard let deployment = graph[oldDeploymentName] else {
                throw RuntimeError.deploymentToReplaceNotFound(name: oldDeploymentName, configuration: graph.namespace)
            }
            let archivedDeployment = ArchivedDeployment(forDeploymentNamed: oldDeploymentName, in: graph)
            graph.removeDeployment(named: oldDeploymentName, applied: false)
            graph.add(newDeployment, requirementsNames: archivedDeployment.requirements, applied: false)
            for requirer in archivedDeployment.requirers {
                graph.add(requirer --> newDeployment.name)
            }
        case .bind(let deploymentName, let requirmentsNames):
            guard graph[deploymentName] != nil else {
                throw RuntimeError.deploymentToBindNotFound(name: deploymentName, configuration: graph.namespace)
            }
            for requirementName in requirmentsNames {
                guard graph[requirementName] != nil else {
                    throw RuntimeError.requirementNotFound(name: requirementName, configuration: graph.namespace)
                }
            }
            graph.bindDeployment(named: deploymentName, toDeploymentsNamed: requirmentsNames)
        case .release(let deploymentName, let otherDeploymentNames):
            guard graph[deploymentName] != nil else {
                throw RuntimeError.deploymentToReleaseFound(name: deploymentName, configuration: graph.namespace)
            }
            for otherDeploymentName in otherDeploymentNames {
                guard graph[otherDeploymentName] != nil else {
                    throw RuntimeError.deploymentNotFound(name: otherDeploymentName, configuration: graph.namespace)
                }
            }
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
    
    public var isTransparent: Bool {
        switch self {
        case .bind, .release:
            true
        default:
            false
        }
    }
    
    var priority: Int8 {
        switch self {
            case .add(_, _): 4
            case .remove(_): 1
            case .replace(_, _): 5
            case .bind(_, _): 2
            case .release(_, _): 3
        }
    }
}
