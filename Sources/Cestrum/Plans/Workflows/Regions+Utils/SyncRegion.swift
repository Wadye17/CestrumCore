//
//  File.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

/// A compound intermediate type for supporting and representing parallel join regions.
struct SyncRegion: WorkflowRegion {
    let sources: NodeSet
    let syncPoint: Node
    
    @discardableResult
    func build() -> Node? {
        for previousNode in syncPoint.incomingNodes {
            if case .join = previousNode.content {
                // print("This sync (join) region cannot be built because the sync point node already has a parallel join before it.")
                return nil
            }
        }
        let parallelJoin = Node(.join)
        for source in sources {
            source.link(to: parallelJoin)
        }
        parallelJoin.link(to: syncPoint)
        return parallelJoin
    }
}
