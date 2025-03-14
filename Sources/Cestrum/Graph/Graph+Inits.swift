//
//  Graph+Inits.swift
//  CestrumKit
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

/// Convenience initialisers.
extension DependencyGraph {
    /// Creates a new instance of a dependency graph.
    convenience init<C: Collection>(name: String, deployments: C, dependencies: Set<Dependency>) where C.Element == Deployment {
        self.init(name: name, deployments: Set(deployments), dependencies: dependencies)
    }
    
    /// Creates a new instance of a dependecy graph, with only nodes, and no dependencies.
    convenience init<C: Collection>(name: String, deployments: C) where C.Element == Deployment {
        self.init(name: name, deployments: deployments, dependencies: [])
    }
    
    /// Creates a new instance of a dependency graph — variadic initialiser.
    convenience init(name: String, deployments: Deployment..., dependencies: Dependency...) {
        self.init(name: name, deployments: Set(deployments), dependencies: Set(dependencies))
    }
    
    /// Creates a new instance of a dependecy graph, with only nodes, and no dependencies — variadic initialiser.
    convenience init(name: String, deployments: Deployment...) {
        self.init(name: name, deployments: Set(deployments), dependencies: [])
    }
    
    /// Creates a new instance of a dependency graph, with dependencies using a DSL syntax.
    convenience init<C: Collection>(name: String, deployments: C, @DependencyBuilder dependencies: () -> Set<Dependency>) where C.Element == Deployment {
        self.init(name: name, deployments: deployments, dependencies: dependencies())
    }
    
    /// Creates a new instance of a dependency graph, with dependencies using a DSL syntax.
    convenience init(name: String, deployments: Deployment..., @DependencyBuilder dependencies: () -> Set<Dependency>) {
        self.init(name: name, deployments: Set(deployments), dependencies: dependencies())
    }
}
