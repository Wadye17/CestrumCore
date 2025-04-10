//
//  GraphDescription.swift
//  CestrumCore
//
//  Created by Wadÿe on 10/04/2025.
//

import Foundation

/// Represents a description of a graph, used for storing dependency graphs.
///
/// This is only a placeholder component, whilst the CESC language is still not built, yet.
/// The nodes represent the deployments, whilst the arcs represent the dependencies.
public struct GraphDescription: Codable {
    let namespace: String
    let deployments: Set<String>
    let dependencies: Set<Dependency>
    
    public init(namespace: String, nodes: Set<String>, arcs: Set<Dependency>) {
        self.namespace = namespace
        self.deployments = nodes
        self.dependencies = arcs
    }
}
