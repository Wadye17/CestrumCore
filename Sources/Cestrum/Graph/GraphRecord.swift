//
//  GraphRecord.swift
//  CestrumCore
//
//  Created by Wadÿe on 17/04/2025.
//

import Foundation

/// Represents a record of a graph, for versioning and history tracking—in case of a failure or corruption.
struct GraphRecord: Codable {
    let date: Date
    let content: DependencyGraph
    
    init(_ content: DependencyGraph, on date: Date) {
        self.date = date
        self.content = content.createCopy()
    }
}
