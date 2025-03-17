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
    let requirements: Set<Deployment>
    let requirers: Set<Deployment>
    
    public init(for deployment: Deployment, in graph: DependencyGraph) {
        self.deployment = graph.checkPresence(of: deployment)
        graph.checkForCycles()
        self.requirements = deployment.requirements(in: graph)
        self.requirers = deployment.requirers(in: graph)
    }
}
