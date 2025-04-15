//
//  ArchivedDeployment.swift
//  Cestrum
//
//  Created by Wadÿe on 12/03/2025.
//

import Foundation

/// Represents an archive of a deployment that can be replaced with another, saving its requirements and requirers.
public struct ArchivedDeployment {
    let deployment: Deployment
    let requirements: Set<String>
    let requirers: Set<String>
    
    public init(for deployment: Deployment, in graph: DependencyGraph) {
        self.deployment = graph.checkPresence(of: deployment)
        self.requirements = Set(deployment.requirements(in: graph).map(\.name))
        self.requirers = Set(deployment.requirers(in: graph).map(\.name))
    }
    
    public init(forDeploymentNamed name: String, in graph: DependencyGraph) {
        self.deployment = graph.checkPresence(ofDeploymentNamed: name)
        graph.checkForCycles()
        self.requirements = Set(deployment.requirements(in: graph).map(\.name))
        self.requirers = Set(deployment.requirers(in: graph).map(\.name))
    }
}
