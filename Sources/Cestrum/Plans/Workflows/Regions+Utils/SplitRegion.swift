//
//  SplitRegion.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

/// A compound intermediate type for representing and building parallel split regions.
struct SplitRegion: WorkflowRegion {
    let source: Node
    let splits: NodeSet
    
    @discardableResult
    func build() -> Node? {
        for nextNode in source.outgoingNodes {
            if case .split = nextNode.content {
                // print("This split region cannot be built because the source node already flows into a parallel split.")
                return nil
            }
        }
        let parallelSplit = Node(.split)
        self.source.link(to: parallelSplit)
        parallelSplit.link(to: splits)
        return parallelSplit
    }
}
