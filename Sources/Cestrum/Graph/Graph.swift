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
    var deployments: Set<Deployment>
    /// The set of dependencies.
    var dependencies: Set<Dependency>
    
    /// Creates a new instance of a dependency graph.
    public init(name: String, deployments: Set<Deployment>, dependencies: Set<Dependency>) throws {
        self.namespace = name
        self.deployments = deployments
        self.dependencies = dependencies
        try self.boot()
    }
    
    /// Returns the deployment having the given name; returns `nil` if not found.
    subscript(_ name: String) -> Deployment? {
        return self.deployments.first { $0.name == name }
    }
    
    /// Returns the deployment having the given name; returns `nil` if not found.
    subscript(_ deployment: Deployment) -> Deployment? {
        return self.deployments.first { $0 == deployment }
    }
    
    /// Returns the set of deployments with the given status.
    public subscript(_ status: Status) -> Set<Deployment> {
        return self.deployments.filter { $0.status == status }
    }
    
    /// Returns `true` if the given deployment exists in this graph.
    public func contains(_ deployment: Deployment) -> Bool {
        return self.deployments.contains(deployment)
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
        return deployment
    }
    
    /// Returns the desired deployment by name — crashes the program when the deployment is not found.
    ///
    /// Use only when finding the deployment is critical.
    /// For a safe retrieval, use either subscripts.
    @discardableResult
    public func checkPresence(ofDeploymentNamed name: String) -> Deployment {
        guard let deployment = self[name] else {
            fatalError("Fatal error: Deployment \(name) does not exist in graph \(self.namespace).")
        }
        return deployment
    }
    
    /// Returns the desired deployments by names — crashes the program when at least one deployment is not found.
    ///
    /// Use only when finding the deployments is critical.
    /// For a safe retrieval, use either subscripts.
    @discardableResult
    public func checkPresence(ofDeploymentsNamed names: Set<String>) -> Set<Deployment> {
        var result = Set<Deployment>()
        for name in names {
            let deployment = self.checkPresence(ofDeploymentNamed: name)
            result.insert(deployment)
        }
        return result
    }
    
    /// Returns the set of deployments that the given deployment requires (i.e., depends on).
    public func getRequirements(ofDeploymentNamed name: String) -> Set<Deployment> {
        let actualDeployment = self.checkPresence(ofDeploymentNamed: name)
        let requirementsNames = Set(self.dependencies.filter({ $0.source == actualDeployment.name }).map(\.target))
        let actualRequirements = self.checkPresence(ofDeploymentsNamed: requirementsNames)
        return actualRequirements
    }
    
    /// Returns the set of deployments that require (i.e., depend on) the given deployment.
    public func getRequirers(ofDeploymentNamed name: String) -> Set<Deployment> {
        let actualDeployment = self.checkPresence(ofDeploymentNamed: name)
        let requirersNames = Set(self.dependencies.filter({ $0.target == actualDeployment.name }).map(\.source))
        let actualRequirers = self.checkPresence(ofDeploymentsNamed: requirersNames)
        return actualRequirers
    }
    
    /// Returns the transitive closure of requirements of the deployment with the given name.
    ///
    /// If A --> B, and B --> C; then the transitive requirements of A are B and C; and so on.
    public func getTransitiveRequirements(ofDeploymentNamed name: String) -> Set<Deployment> {
        self.fatalCheckForCycles()
        
        var visited = Set<String>()
        var result = Set<Deployment>()
        
        func dfs(_ currentName: String) {
            guard !visited.contains(currentName) else { return }
            visited.insert(currentName)
            
            let requirers = getRequirements(ofDeploymentNamed: currentName)
            result.formUnion(requirers)
            
            for requirer in requirers {
                dfs(requirer.name)
            }
        }
        
        dfs(name)
        return result
    }
    
    /// Returns the transitive closure of requirers of the deployment with the given name.
    ///
    /// If A --> B, and B --> C; then the transitive requirers of C are A and B; and so on.
    public func getTransitiveRequirers(ofDeploymentNamed name: String) -> Set<Deployment> {
        self.fatalCheckForCycles()
        
        var visited = Set<String>()
        var result = Set<Deployment>()
        
        func dfs(_ currentName: String) {
            guard !visited.contains(currentName) else { return }
            visited.insert(currentName)
            
            let requirers = getRequirers(ofDeploymentNamed: currentName)
            result.formUnion(requirers)
            
            for requirer in requirers {
                dfs(requirer.name)
            }
        }
        
        dfs(name)
        return result
    }
    
    /// Adds the given deployment to the graph and handles its dependencies.
    public func add<C: Sequence>(_ deployment: Deployment, requirements: C = [], applied: Bool = true) where C.Element == Deployment {
        if !self.deployments.insert(deployment).inserted {
            print("Warning: Deployment \(deployment) already exists in graph \(self.namespace).")
        }
        for requirement in requirements {
            let actualRequirement = self.checkPresence(of: requirement)
            self.dependencies.insert(Dependency(source: deployment.name, target: actualRequirement.name))
        }
        if applied { print("added \(deployment)")}
    }
    
    /// Adds the given deployment to the graph and handles its dependencies.
    public func add<C: Sequence>(_ deployment: Deployment, requirementsNames: C = [], applied: Bool = true) where C.Element == String {
        if !self.deployments.insert(deployment).inserted {
            print("Warning: Deployment \(deployment) already exists in graph \(self.namespace).")
        }
        for requirement in requirementsNames {
            let actualRequirement = self.checkPresence(ofDeploymentNamed: requirement)
            self.dependencies.insert(Dependency(source: deployment.name, target: actualRequirement.name))
        }
        if applied { print("added \(deployment)")}
    }
    
    public func add(_ dependency: Dependency) {
        self.checkPresence(ofDeploymentNamed: dependency.source)
        self.checkPresence(ofDeploymentNamed: dependency.target)
        self.dependencies.insert(dependency)
    }
    
    public func bindDeployment(named deploymentName: String, toDeploymentsNamed requirementsNames: Set<String>) {
        self.checkPresence(ofDeploymentNamed: deploymentName)
        self.checkPresence(ofDeploymentsNamed: requirementsNames)
        for requirement in requirementsNames {
            self.add(deploymentName --> requirement)
        }
    }
    
    public func unbindDeployment(name deploymentName: String, fromDeploymentsNamed otherDeployments: Set<String>) {
        self.checkPresence(ofDeploymentNamed: deploymentName)
        self.checkPresence(ofDeploymentsNamed: otherDeployments)
        for dependency in dependencies where dependency.contains(deploymentName) {
            for deployment in otherDeployments {
                if dependency.contains(deployment) {
                    self.dependencies.remove(dependency)
                }
            }
        }
    }
    
    /// Removes the given deployment from the graph and automatically handles the dependencies.
    public func removeDeployment(_ deployment: Deployment, applied: Bool = true) {
        self.checkPresence(of: deployment)
        self.dependencies.subtract(Set(self.dependencies.filter { $0.contains(deployment.name) }))
        self.deployments.remove(deployment)
        if applied { print("removed \(deployment)") }
    }
    
    /// Removes the deployment with the given name from the graph, and automatically handles the removal of the dependencies involving it.
    public func removeDeployment(named name: String, applied: Bool = true) {
        let actualDeployment = self.checkPresence(ofDeploymentNamed: name)
        self.removeDeployment(actualDeployment, applied: applied)
    }
    
    /// Starts all the deployments with respect to this dependency graph.
    func boot() throws {
        guard !self.hasCycles else {
            throw RuntimeError.cyclicConfiguration(name: self.namespace)
        }
        for deployment in deployments {
            deployment.start(considering: self)
        }
    }
    
    public func generateConcretePlan(from abstractPlan: AbstractFormula) throws(RuntimeError) -> ConcretePlan {
        let targetGraph = try abstractPlan.createTargetGraph(from: self)
        let concretePlan = ConcretePlan(from: self, to: targetGraph)
        return concretePlan
    }
    
    public func generateConcreteWorkflow(from abstractPlan: AbstractFormula) throws(RuntimeError) -> ConcreteWorkflow {
        let targetGraph = try abstractPlan.createTargetGraph(from: self)
        let workflow = ConcreteWorkflow(initialGraph: self, targetGraph: targetGraph)
        return workflow
    }
}

extension DependencyGraph: CustomStringConvertible {
    public var description: String {
        """
        graph \(self.namespace) {
            deployments {\(self.deployments.map(\.description).sorted().joined(separator: ", "))}
            dependencies {
            \t\(self.dependencies.map(\.description).sorted().joined(separator: "\n\t\t"))
            }
        }
        """
    }
}

extension DependencyGraph: Hashable {
    public static func == (_ lhs: DependencyGraph, _ rhs: DependencyGraph) -> Bool {
        lhs.namespace == rhs.namespace
        && lhs.deployments == rhs.deployments
        && lhs.dependencies == rhs.dependencies
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.namespace)
        hasher.combine(self.deployments)
        hasher.combine(self.dependencies)
    }
}
