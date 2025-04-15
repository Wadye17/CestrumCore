//
//  Graph+Cycles.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

extension DependencyGraph {
    /// Crashes the programme if this dependency graph contains at least a cycle.
    public func checkForCycles() {
        guard !self.hasCycles else {
            fatalError("Fatal error: Graph \(self.namespace) exhibits at least one cycle; crashed the process because this should not happen")
        }
    }
    
    /// Returns `true` if this graph contains cycles.
    public var hasCycles: Bool {
        for dependency in self.dependencies {
            guard !dependency.isReflexive else {
                return false
            }
        }
        
        for dependency in self.dependencies {
            guard !dependency.isReflexive else { return true }
            var visitedObjects: Set<String> = []
            return hasCycled(currentDeployment: dependency.source, visited: &visitedObjects)
        }
        return false
    }
    
    /// Returns `true` if the given deployment cycles with its dependencies.
    private func hasCycled(currentDeployment: String, visited: inout Set<String>) -> Bool {
        if visited.contains(currentDeployment) { return true }
        visited.insert(currentDeployment)
        for requirement in self.getRequirements(ofDeploymentNamed: currentDeployment) {
            return self.hasCycled(currentDeployment: requirement.name, visited: &visited)
        }
        return false
    }
}
