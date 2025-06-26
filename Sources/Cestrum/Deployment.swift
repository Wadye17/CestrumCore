//
//  Deployment.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

/// Represents an abstraction of a deployment in Kubernetes.
public final class Deployment: Codable {
    /// The name of the deployment as in Kubernetes.
    public let name: String
    
    /// The path to the manifest of the deployment.
    public let manifestPath: String?
    
    /// The theoretical status of the deployment.
    public private(set) var status: Status
    
    /// Creates a new instance of a deployment.
    init(_ name: String, manifestPath: String? = nil, _ status: Status) {
        self.name = name
        self.manifestPath = manifestPath
        self.status = status
    }
    
    /// Creates a new, uninitialised instance of a deployment.
    convenience init(_ name: String, manifestPath: String? = nil) {
        self.init(name, manifestPath: manifestPath, .stopped)
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case status
    }
    
    /// Decodes the deployment from a name and a status.
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.status = try container.decode(Status.self, forKey: .status)
        self.manifestPath = nil
    }
    
    /// Encodes this deployment, considering only its name and status.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.status, forKey: .status)
    }
    
    /// Marks the deployment as started.
    func forceStart() {
        self.status = .started
    }
    
    /// Marks the deployment as stopped.
    func forceStop() {
        self.status = .stopped
    }
    
    /// Starts the deployment with respect to the dependency graph provided.
    func start(considering graph: DependencyGraph) {
        for requirement in self.requirements(in: graph) where requirement.status == .stopped {
            requirement.start(considering: graph)
        }
        if self.status != .started {
            self.status = .started
        }
        for requirer in self.requirers(in: graph) where requirer.status == .stopped {
            requirer.start(considering: graph)
        }
    }
    
    /// Starts the deployment with respect to the dependency graph provided.
    func start(considering graph: DependencyGraph, atomicPlan: inout [ConcreteOperation]) {
        for requirement in self.requirements(in: graph) where requirement.status == .stopped {
            requirement.start(considering: graph, atomicPlan: &atomicPlan)
        }
        if self.status != .started {
            self.status = .started
            atomicPlan.append(.start(self, graph))
        }
        for requirer in self.requirers(in: graph) where requirer.status == .stopped {
            requirer.start(considering: graph, atomicPlan: &atomicPlan)
        }
    }
    
    /// Stops the deployment with respect to the dependency graph provided.
    func stop(considering graph: DependencyGraph) {
        for requirer in self.requirers(in: graph) where requirer.status == .started {
            requirer.stop(considering: graph)
        }
        if self.status != .stopped {
            self.status = .stopped
        }
    }
    
    /// Stops the deployment with respect to the dependency graph provided.
    func stop(considering graph: DependencyGraph, atomicPlan: inout [ConcreteOperation]) {
        for requirer in self.requirers(in: graph) where requirer.status == .started {
            requirer.stop(considering: graph, atomicPlan: &atomicPlan)
        }
        if self.status != .stopped {
            self.status = .stopped
            atomicPlan.append(.stop(self, graph))
        }
    }
    
    /// Returns the set of deployments that require this deployment in the given graph.
    ///
    /// This is a shorthand function and is equivalent to using `getRequirements(of: deployment)`
    /// in the context of `DependencyGraph`.
    func requirements(in graph: DependencyGraph) -> Set<Deployment> {
        return graph.getRequirements(ofDeploymentNamed: self.name)
    }
    
    /// Returns the set of deployments that this deployment requires in the given graph.
    ///
    /// This is a shorthand function and is equivalent to using `getRequirers(of: deployment)`
    /// in the context of `DependencyGraph`.
    func requirers(in graph: DependencyGraph) -> Set<Deployment> {
        return graph.getRequirers(ofDeploymentNamed: self.name)
    }
    
    func globalRequirements(in graph: DependencyGraph) -> Set<Deployment> {
        return graph.getTransitiveRequirements(ofDeploymentNamed: self.name)
    }
    
    func globalRequirers(in graph: DependencyGraph) -> Set<Deployment> {
        return graph.getTransitiveRequirers(ofDeploymentNamed: self.name)
    }
}

extension Deployment: Hashable {
    public static func == (lhs: Deployment, rhs: Deployment) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
}

extension Deployment: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: String) {
        self.init(value)
    }
}

extension Deployment: CustomStringConvertible {
    public var description: String {
        self.name
    }
    
    public var fullDescription: String {
        "\(self.name)-\(self.status)"
    }
}
