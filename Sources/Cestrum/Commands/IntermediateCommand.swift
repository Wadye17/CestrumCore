//
//  IntermediateCommand.swift
//  CestrumKit
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

/// Represents an intermediate representation of an abstract command.
public enum IntermediateCommand: TranslatableCommand {
    typealias TargetTranslationCommand = AtomicCommand
    
    case add(Deployment, requirements: Set<Deployment>, archivedDeployment: ArchivedDeployment?)
    case remove(Deployment, asPartOfReplacement: Bool)
    
    func translate(considering graph: DependencyGraph) -> [AtomicCommand] {
        graph.checkForCycles()
        var result = [AtomicCommand]()
        switch self {
        case .add(let deployment, let requirements, let archivedDeployment):
            graph.add(deployment, requirements: requirements, applied: false)
            result.append(.add(deployment, graph))
            if let archivedDeployment {
                for target in archivedDeployment.requirements {
                    graph.add(Dependency(source: deployment, target: target))
                }
                for source in archivedDeployment.requirers {
                    graph.add(Dependency(source: source, target: deployment))
                }
                for requirer in deployment.requirers(in: graph) {
                    requirer.start(considering: graph, atomicPlan: &result)
                }
            }
            deployment.start(considering: graph, atomicPlan: &result)
        case .remove(let deployment, let asPartOfReplacement):
            let actualDeployment = graph.checkPresence(of: deployment)
            let requirers = actualDeployment.requirers(in: graph)
            actualDeployment.stop(considering: graph, atomicPlan: &result)
            graph.remove(actualDeployment, applied: false)
            result.append(.remove(actualDeployment, graph))
            if !asPartOfReplacement {
                for requirer in requirers {
                    requirer.start(considering: graph, atomicPlan: &result)
                }
            }
        }
        return result
    }
    
    public var description: String {
        switch self {
        case .add(let deployment, let requirements, let archivedDeployment):
            if let archivedDeployment {
                "add \(deployment) requiring {\(archivedDeployment.requirements.map(\.description).joined(separator: ", "))}"
            } else {
                "add \(deployment) requiring {\(requirements.map(\.description).joined(separator: ", "))}"
            }
        case .remove(let deployment, _):
            "remove \(deployment)"
        }
    }
}
