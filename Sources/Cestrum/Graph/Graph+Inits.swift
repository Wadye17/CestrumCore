//
//  Graph+Inits.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

/// Convenience initialisers.
extension DependencyGraph {
    /// Creates a new instance of a dependency graph.
    convenience init<C: Collection>(name: String, deployments: C, dependencies: Set<Dependency>) throws where C.Element == Deployment {
        try self.init(name: name, deployments: Set(deployments), dependencies: dependencies)
    }
    
    /// Creates a new instance of a dependecy graph, with only nodes, and no dependencies.
    convenience init<C: Collection>(name: String, deployments: C) throws where C.Element == Deployment {
        try self.init(name: name, deployments: deployments, dependencies: [])
    }
    
    /// Creates a new instance of a dependency graph — variadic initialiser.
    convenience init(name: String, deployments: Deployment..., dependencies: Dependency...) throws {
        try self.init(name: name, deployments: Set(deployments), dependencies: Set(dependencies))
    }
    
    /// Creates a new instance of a dependecy graph, with only nodes, and no dependencies — variadic initialiser.
    convenience init(name: String, deployments: Deployment...) throws {
        try self.init(name: name, deployments: Set(deployments), dependencies: [])
    }
    
    /// Creates a new instance of a dependency graph, with dependencies using a DSL syntax.
    convenience init<C: Collection>(name: String, deployments: C, @DependencyBuilder dependencies: () -> Set<Dependency>) throws where C.Element == Deployment {
        try self.init(name: name, deployments: deployments, dependencies: dependencies())
    }
    
    /// Creates a new instance of a dependency graph, with dependencies using a DSL syntax.
    convenience init(name: String, deployments: Deployment..., @DependencyBuilder dependencies: () -> Set<Dependency>) throws {
        try self.init(name: name, deployments: Set(deployments), dependencies: dependencies())
    }
    
    /// Creates a new instance of a dependency graph from a given graph description instance.
    ///
    /// ``GraphDescription`` is a placeholder component whilst the CESC (Cestrum Configuration) language is not yet built.
    convenience public init(description: GraphDescription) throws {
        let actualDeployments = Set(description.deployments.map { Deployment($0, .started) })
        try self.init(
            name: description.namespace,
            deployments: actualDeployments,
            dependencies: description.dependencies
        )
    }
}
