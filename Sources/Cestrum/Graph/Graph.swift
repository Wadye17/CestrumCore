//
//  Graph.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

/// Represents a dependency graph between deployments.
public final class DependencyGraph: DeepCopyable {
    /// The name of the graph.
    public let namespace: String
    /// The set of deployments.
    var nodes: Set<Deployment>
    /// The set of dependencies.
    var arcs: Set<Dependency>
    
    /// Creates a new instance of a dependency graph.
    public init(name: String, deployments: Set<Deployment>, dependencies: Set<Dependency>) {
        self.namespace = name
        self.nodes = deployments
        self.arcs = dependencies
        self.boot()
    }
    
    /// Used for encoding and decoding.
    private enum CodingKeys: String, CodingKey {
        case namespace, nodes, arcs
    }
    
    /// Custom decoding to ensure the dependencies' elements reference the correct `Deployment` instances.
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.namespace = try container.decode(String.self, forKey: .namespace)
        self.nodes = try container.decode(Set<Deployment>.self, forKey: .nodes)

        let deploymentMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.name, $0) })
        let decodedArcs = try container.decode([[String: String]].self, forKey: .arcs)

        self.arcs = Set(decodedArcs.compactMap { dict in
            guard let sourceName = dict["source"], let targetName = dict["target"],
                  let sourceDeployment = deploymentMap[sourceName],
                  let targetDeployment = deploymentMap[targetName] else { return nil }
            return Dependency(source: sourceDeployment, target: targetDeployment)
        })
    }
    
    /// Returns the deployment having the given name; returns `nil` if not found.
    subscript(_ name: String) -> Deployment? {
        return self.nodes.first { $0.name == name }
    }
    
    /// Returns the deployment having the given name; returns `nil` if not found.
    subscript(_ deployment: Deployment) -> Deployment? {
        return self.nodes.first { $0 == deployment }
    }
    
    /// Returns the set of deployments with the given status.
    public subscript(_ status: Status) -> Set<Deployment> {
        return self.nodes.filter { $0.status == status }
    }
    
    /// Returns `true` if the given deployment exists in this graph.
    public func contains(_ deployment: Deployment) -> Bool {
        return self.nodes.contains(deployment)
    }
    
    /// Returns the desired deployment — crashes the program when the deployment is not found.
    ///
    /// Use only when finding the deployment is critical.
    /// For a safe retrieval, use either subscripts.
    @discardableResult
    public func checkPresence(of d: Deployment) -> Deployment {
        guard let deployment = self[d] else {
            fatalError("Fatal error: Deployment \(d) does not exist in graph \(self.namespace).")
        }
        if let manifest = d.manifest {
            deployment.manifest = manifest
        }
        return deployment
    }
    
    /// Returns the set of deployments that the given deployment requires (i.e., depends on).
    public func getRequirements(of deployment: Deployment) -> Set<Deployment> {
        let actualDeployment = self.checkPresence(of: deployment)
        return Set(self.arcs.filter({ $0.source == actualDeployment }).map(\.target))
    }
    
    /// Returns the set of deployments that require (i.e., depend on) the given deployment.
    public func getRequirers(of deployment: Deployment) -> Set<Deployment> {
        let actualDeployment = self.checkPresence(of: deployment)
        return Set(self.arcs.filter({ $0.target == actualDeployment }).map(\.source))
    }
    
    /// Adds the given deployment to the graph and handles its dependencies.
    public func add<C: Sequence>(_ deployment: Deployment, requirements: C, applied: Bool = true) where C.Element == Deployment {
        if !self.nodes.insert(deployment).inserted {
            print("Warning: Deployment \(deployment) already exists in graph \(self.namespace).")
        }
        for requirement in requirements {
            let actualRequirement = self.checkPresence(of: requirement)
            self.arcs.insert(Dependency(source: deployment, target: actualRequirement))
        }
        if applied { print("added \(deployment)")}
    }
    
    public func add(_ dependency: Dependency) {
        self.checkPresence(of: dependency.source)
        self.checkPresence(of: dependency.target)
        self.arcs.insert(dependency)
    }
    
    /// Removes the given deployment from the graph and automatically handles the dependencies.
    public func remove(_ deployment: Deployment, applied: Bool = true) {
        self.checkPresence(of: deployment)
        self.arcs.subtract(Set(self.arcs.filter { $0.contains(deployment) }))
        self.nodes.remove(deployment)
        if applied { print("removed \(deployment)") }
    }
    
    /// Starts all the deployments with respect to this dependency graph.
    func boot() {
        self.checkForCycles()
        for deployment in nodes {
            deployment.start(considering: self)
        }
    }
    
    public func generatePlan(from abstractPlan: AbstractPlan) -> ConcretePlan {
        let targetGraph = abstractPlan.createTarget(on: self)
        let concretePlan = ConcretePlan(from: self, to: targetGraph)
        return concretePlan
    }
}

extension DependencyGraph: CustomStringConvertible {
    public var description: String {
        """
        graph \(self.namespace) {
            nodes {\(self.nodes.map(\.fullDescription).sorted().joined(separator: ", "))}
            dependencies {
            \t\(self.arcs.map(\.description).sorted().joined(separator: "\n\t\t"))
            }
        }
        """
    }
}

extension DependencyGraph: Hashable {
    public static func == (_ lhs: DependencyGraph, _ rhs: DependencyGraph) -> Bool {
        lhs.namespace == rhs.namespace
        && lhs.nodes == rhs.nodes
        && lhs.arcs == rhs.arcs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.namespace)
        hasher.combine(self.nodes)
        hasher.combine(self.arcs)
    }
}
