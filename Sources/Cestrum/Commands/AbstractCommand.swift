//
//  AbstractCommand.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

public enum AbstractCommand: TranslatableCommand {
    public typealias TargetTranslationCommand = IntermediateCommand
    
    case add(Deployment, requirements: Set<Deployment>)
    case remove(Deployment)
    case replace(oldDeployment: Deployment, newDeployment: Deployment)
    
    public func translate(considering graph: DependencyGraph) -> [IntermediateCommand] {
        switch self {
        case .add(let deployment, let requirements):
            guard graph[deployment] == nil else {
                print("Warning: Deployment \(self) already exists in graph \(graph.namespace)")
                return []
            }
            return [.add(deployment, requirements: requirements, archivedDeployment: nil)]
        case .remove(let deployment):
            return [.remove(deployment, asPartOfReplacement: false)]
        case .replace(let oldDeployment, let newDeployment):
            return [.remove(oldDeployment, asPartOfReplacement: true), .add(newDeployment, requirements: [], archivedDeployment: ArchivedDeployment(for: oldDeployment, in: graph))]
        }
    }
    
    public func reflect(considering graph: DependencyGraph) {
        switch self {
        case .add(let deployment, let requirements):
            graph.add(deployment, requirements: requirements, applied: false)
        case .remove(let deployment):
            graph.remove(deployment, applied: false)
        case .replace(let oldDeployment, let newDeployment):
            let actualOldDeployment = graph.checkPresence(of: oldDeployment)
            let archivedDeployment = ArchivedDeployment(for: actualOldDeployment, in: graph)
            graph.remove(actualOldDeployment, applied: false)
            graph.add(newDeployment, requirements: archivedDeployment.requirements, applied: false)
            for requirer in archivedDeployment.requirers {
                graph.add(requirer --> newDeployment)
            }
        }
    }
    
    public var description: String {
        switch self {
        case .add(let deployment, let requirements):
            "add \(deployment) requiring {\(requirements.map(\.description).joined(separator: ", "))}"
        case .remove(let deployment):
            "remove \(deployment)"
        case .replace(let oldDeployment, let newDeployment):
            "replace \(oldDeployment) with \(newDeployment)"
        }
    }
}
