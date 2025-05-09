//
//  SimpleSequence.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

/// A compound intermediate type for representing and building ordinary sequence flows.
struct SimpleSequence: WorkflowRegion {
    let source: Node
    let target: Node
    
    func build() {
        guard !source.outgoingNodes.contains(target) else {
            // print("Sequence cannot be built because it already is.")
            return
        }
        source.link(to: target)
    }
}
