//
//  DependencyBuilder.swift
//  CestrumKit
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

@resultBuilder
struct DependencyBuilder {
    static func buildExpression(_ dependency: Dependency) -> Set<Dependency> {
        return [dependency]
    }
    
    static func buildExpression(_ dependencies: Set<Dependency>) -> Set<Dependency> {
        return dependencies
    }
    
    static func buildBlock(_ dependencies: Set<Dependency>...) -> Set<Dependency> {
        return Set(dependencies.flatMap { $0 })
    }
}
