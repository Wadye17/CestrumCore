//
//  File.swift
//  CestrumCore
//
//  Created by Wadÿe on 16/09/2025.
//

import Foundation

/// Represents a set of ordering constraints.
typealias OrderingConstraintSet = Set<OrderingConstraint>

extension OrderingConstraintSet {
    /// Creates the set of stop ordering constraints
    /// - Parameter delta: The delta between a source and a target graph.
    /// - Returns: A set of ordering constraints.
    static func stopSet(delta: Delta) -> Self {
        var result = OrderingConstraintSet()
        let sourceGraph = delta.sourceGraph
        for deployment in sourceGraph.deployments
        where delta.deploymentsToStop.contains(deployment) {
            for requirement in deployment.requirements(in: sourceGraph)
            where delta.deploymentsToStop.contains(requirement) {
                result.insert(OrderingConstraint(.stop(deployment, sourceGraph), .stop(requirement, sourceGraph)))
            }
        }
        return result
    }
    
    /// Creates the set of stop ordering constraints
    /// - Parameter delta: The delta between a source and a target graph.
    /// - Returns: A set of ordering constraints.
    static func startSet(delta: Delta) -> Self {
        var result = OrderingConstraintSet()
        let targetGraph = delta.targetGraph
        for deployment in targetGraph.deployments
        where delta.deploymentsToStart.contains(deployment) {
            for requirer in deployment.requirers(in: targetGraph) {
                result.insert(OrderingConstraint(.start(deployment, targetGraph), .start(requirer, targetGraph)))
            }
        }
        return result
    }
    
    /// Returns a set containing the ordering constraints sufficient to construct the confluent plan.
    static func confluentSet(from delta: Delta) -> Self {
        let startSet = Self.startSet(delta: delta)
        let stopSet = Self.stopSet(delta: delta)
        var result = stopSet.union(startSet)
        for deploymentToRemove in delta.deploymentsToRemove {
            result.insert(
                OrderingConstraint(
                    .stop(deploymentToRemove, delta.sourceGraph),
                    .remove(deploymentToRemove, delta.sourceGraph)
                )
            )
        }
        for deploymentToAdd in delta.deploymentsToAdd {
            result.insert(
                OrderingConstraint(
                    .add(deploymentToAdd, delta.targetGraph),
                    .start(deploymentToAdd, delta.targetGraph)
                )
            )
        }
        for deploymentToStop in delta.deploymentsToStop
        where !delta.deploymentsToRemove.contains(deploymentToStop) {
            result.insert(
                OrderingConstraint(
                    .stop(deploymentToStop, delta.sourceGraph),
                    .start(deploymentToStop, delta.targetGraph)
                )
            )
        }
        if let complementaryInfo = delta.complementaryInformation {
            for info in complementaryInfo {
                if case .replacement(let oldDeploymentName, let newDeploymentName) = info {
                    let oldDeployment = delta.allDeployments.first(where: { $0.name == oldDeploymentName })!
                    let newDeployment = delta.allDeployments.first(where: { $0.name == newDeploymentName })!
                    result.insert(
                        OrderingConstraint(
                            .remove(oldDeployment, delta.sourceGraph),
                            .start(newDeployment, delta.targetGraph)
                        )
                    )
                }
            }
        }
        return result
    }
}
