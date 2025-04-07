//
//  Dependency.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

/// Represents a source-target dependency between two deployments.
///
/// For two deployments a and b, we note "a --> b" if deployment a depends on deployment b.
public struct Dependency: Hashable, Codable {
    let source: String
    let target: String
    
    public init(source: Deployment, target: Deployment) {
        self.init(source: source.name, target: target.name)
    }
    
    /// Creates a dependency between a source deployment and a target deployment.
    public init(source: String, target: String) {
        self.source = source
        self.target = target
    }
    
    /// Returns `true` if this dependency is reflexive, i.e., the source and target are the same.
    public var isReflexive: Bool {
        source == target
    }
    
    /// Returns `true` if this dependency has the given deployment as either its source or its target.
    public func contains(_ deployment: String) -> Bool {
        source == deployment || target == deployment
    }
    
    private enum CodingKeys: String, CodingKey {
        case source, target
    }
    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(source.name, forKey: .source)
//        try container.encode(target.name, forKey: .target)
//    }
}

/// A custom operator that allows to express a source-target dependency between two deployments.
infix operator -->

/// Establishes a source-target dependency between two deployments.
public func --> (_ source: String, _ target: String) -> Dependency {
    return Dependency(source: source, target: target)
}

/// Establishes a source-target dependency between two deployments.
public func --> (_ source: Deployment, _ target: Deployment) -> Dependency {
    return Dependency(source: source, target: target)
}

public func --> (_ source: String, _ targets: [String]) -> Set<Dependency> {
    var result = Set<Dependency>()
    for target in targets {
        result.insert(Dependency(source: source, target: target))
    }
    return result
}

public func --> (_ source: Deployment, _ targets: [String]) -> Set<Dependency> {
    var result = Set<Dependency>()
    for target in targets {
        result.insert(Dependency(source: source.name, target: target))
    }
    return result
}

public func --> (_ source: Deployment, _ targets: [Deployment]) -> Set<Dependency> {
    var result = Set<Dependency>()
    for target in targets {
        result.insert(Dependency(source: source.name, target: target.name))
    }
    return result
}

extension Dependency: CustomStringConvertible {
    public var description: String {
        "(\(source) --> \(target))"
    }
}
