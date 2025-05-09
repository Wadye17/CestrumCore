//
//  Flow+Set.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

/// A set of flows.
typealias FlowSet = Set<Flow>

extension FlowSet {
    /// Returns the set of all source nodes.
    var allSources: NodeSet {
        return NodeSet(self.map { $0.source })
    }
    
    /// Returns the set of all target nodes.
    var allTargets: NodeSet {
        return NodeSet(self.map { $0.target })
    }
    
    /// Returns the nodes present in all the flows (source and target, unified).
    var allElements: NodeSet {
        return self.allSources
            .union(self.allTargets)
    }
    
    /// Returns the set of nodes that are regarded as initial, i.e., never appear as targets.
    var initialNodes: NodeSet {
        return allSources.filter { !allTargets.contains($0) }
    }
    
    /// Returns the set of nodes that are regarded as final, i.e., never appear as sources.
    var finalNodes: NodeSet {
        return allTargets.filter { !allSources.contains($0) }
    }
    
    /// Returns the set of nodes (in a compound structure) that will branch into parallel flows, i.e., appear more than once as sources.
    var splitRegions: Set<SplitRegion> {
        let sources = self.allSources
        var result: Set<SplitRegion> = []
        for source in sources {
            let arcsWithThisSource = self.filter { $0.source == source }
            if arcsWithThisSource.count > 1 {
                let splits = NodeSet(arcsWithThisSource.map { $0.target })
                let splitRegion = SplitRegion(source: source, splits: splits)
                result.insert(splitRegion)
            }
        }
        return result
    }
    
    /// Returns the set of nodes (in a compound structure) that will join into one flow, i.e., appear more than once as targets.
    var syncRegions: Set<SyncRegion> {
        let targets = self.allTargets
        var result: Set<SyncRegion> = []
        for target in targets {
            let arcsWithThisTarget = self.filter { $0.target == target }
            if arcsWithThisTarget.count > 1 {
                let sources = NodeSet(arcsWithThisTarget.map { $0.source })
                let syncRegion = SyncRegion(sources: sources, syncPoint: target)
                result.insert(syncRegion)
            }
        }
        return result
    }
    
    /// Returns the set of sequence regions.
    var simpleSequences: Set<SimpleSequence> {
        var result: Set<SimpleSequence> = []
        for source in self.allSources {
            let arcsWithThisSource = self.filter { $0.source == source }
            guard arcsWithThisSource.count == 1, let arc = arcsWithThisSource.first else {
                continue
            }
            let arcTarget = arc.target
            let arcsWithThisTarget = self.filter { $0.target == arcTarget }
            guard arcsWithThisTarget.count == 1, let arcWithThisTarget = arcsWithThisTarget.first, arcWithThisTarget == arc else {
                continue
            }
            let sequence = SimpleSequence(source: source, target: arcTarget)
            result.insert(sequence)
        }
        return result
    }
    
    /// Removes the tangents from the flow set.
    ///
    /// An example of a tangent would be: for a flow set {(A, B), (A, C), (B, C)}, the flow (A, C) is a tangent.
    mutating func removeTangents() {
        for tangent in self.getTangents() {
            self.remove(tangent)
        }
    }
    
    /// Retrieves the tangent within this flow set.
    ///
    /// An example of a tangent would be: for a flow set {(A, B), (A, C), (B, C)}, the flow (A, C) is a tangent.
    private func getTangents() -> FlowSet {
        var tangents = Set<Flow>()
        for flow in self {
            var adjacencyList: [Node: Set<Node>] = [:]
            
            for f in self where f != flow {
                adjacencyList[f.source, default: []].insert(f.target)
            }
            
            if hasPath(from: flow.source, to: flow.target, in: adjacencyList) {
                tangents.insert(flow)
            }
        }
        return tangents
        
        func hasPath(from source: Node, to target: Node, in graph: [Node: Set<Node>]) -> Bool {
            var visited: Set<Node> = []
            var queue: [Node] = [source]
            while let current = queue.first {
                queue.removeFirst()
                if current == target {
                    return true
                }
                if visited.contains(current) { continue }
                visited.insert(current)
                queue.append(contentsOf: graph[current] ?? [])
            }
            return false
        }
    }
    
    static func create(from neighbouredCommands: Set<NeighbouredCommand>) -> (flows: FlowSet, nodes: NodeSet) {
        var nodes = NodeSet(neighbouredCommands.map { Node(.task($0.content)) })
        var flows = FlowSet()
        for neighbouredCommand in neighbouredCommands {
            let content = neighbouredCommand.content
            for predecessor in neighbouredCommand.predecessors {
                flows.insert(Flow(source: nodes.task(having: predecessor)!, target: nodes.task(having: content)!))
            }
            for successor in neighbouredCommand.successors {
                flows.insert(Flow(source: nodes.task(having: content)!, target: nodes.task(having: successor)!))
            }
        }
        
        nodes.formUnion(flows.allElements)
        
        return (flows, nodes)
    }
}
