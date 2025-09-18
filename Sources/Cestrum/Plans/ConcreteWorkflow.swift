//
//  ConcreteWorkflow.swift
//  CestrumCore
//
//  Created by Wadÿe on 29/04/2025.
//

import Foundation

/// Represents an executable BPMN workflow consisting of commands that can be run in parallel where safe.
public final class ConcreteWorkflow {
    private(set) var nodes: NodeSet
    private(set) var flows: FlowSet
    
    let initialGraph: DependencyGraph?
    let targetGraph: DependencyGraph?
    
    init(nodes: NodeSet, flows: FlowSet, initialGraph: DependencyGraph? = nil, targetGraph: DependencyGraph? = nil) {
        self.nodes = nodes
        self.flows = flows
        self.initialGraph = initialGraph
        self.targetGraph = targetGraph
    }
    
    init(nodes: NodeSet, naiveFlows: FlowSet, delta: Delta? = nil) {
        if let delta {
            self.initialGraph = delta.sourceGraph
            self.targetGraph = delta.targetGraph
        } else {
            self.initialGraph = nil
            self.targetGraph = nil
        }
        
        self.nodes = NodeSet()
            .union(nodes)
            .union(naiveFlows.allElements)
        
        var naiveFlows = naiveFlows
        naiveFlows.removeTangents()
        
        let simpleSequences = naiveFlows.simpleSequences
        for sequence in simpleSequences {
            sequence.build()
        }
        
        let splitRegions = naiveFlows.splitRegions
        for splitRegion in splitRegions {
            guard let parallelSplit = splitRegion.build() else {
                continue
            }
            self.nodes.insert(parallelSplit)
        }
        
        let syncRegions = naiveFlows.syncRegions
        for syncRegion in syncRegions {
            guard let parallelJoin = syncRegion.build() else {
                continue
            }
            self.nodes.insert(parallelJoin)
        }
        
        // For mending split-join interleaving. Must be done after building regions
        for syncRegion in syncRegions {
            for syncSource in syncRegion.sources {
                for splitRegion in splitRegions {
                    if splitRegion.source == syncSource {
                        for target in splitRegion.splits {
                            if target == syncRegion.syncPoint {
                                guard let joinNode = syncSource.outgoingNodes.first(where: { $0.content.isGateway(specifically: .join) }) else {
                                    fatalError("Node \(syncSource) does not flow into a join gateway; this shouldn't really happen :/")
                                }
                                syncSource.unlink(from: joinNode)
                                
                                guard let splitNode = syncSource.outgoingNodes.first(where: { $0.content.isGateway(specifically: .split) }) else {
                                    fatalError("Node \(syncSource) does not flow into a split gateway; this shouldn't really happen :/")
                                }
                                splitNode.link(to: joinNode)
                                
                                guard let redundantTargetNode = splitNode.outgoingNodes.first(where: { $0 == target }) else {
                                    fatalError("Somehow could not find the redundant target; this shouldn't really happen :/")
                                }
                                splitNode.unlink(from: redundantTargetNode)
                            }
                        }
                    }
                }
            }
        }
        
        self.flows = []
        self.calculateFlows()
        self.nodes.formUnion(flows.allElements)
    }
    
    public convenience init(initialGraph: DependencyGraph, targetGraph: DependencyGraph) {
        let intermediateGraph = initialGraph.createCopy()
        
        var neighbouredCommands: Set<NeighbouredCommand> = []
        
        let deploymentsToRemove = intermediateGraph.deployments.subtracting(targetGraph.deployments)
        var deploymentsToStop: Set<Deployment> = []
        
        for deploymentToRemove in deploymentsToRemove {
            deploymentsToStop.insert(deploymentToRemove)
            deploymentsToStop.formUnion(deploymentToRemove.globalRequirers(in: intermediateGraph))
        }
        
        // print("All deployments to stop:\n\(deploymentsToStop)")
        
        var stopNeighbouredCommands = Set<NeighbouredCommand>()
        
        // stop workflow
        for deploymentToStop in deploymentsToStop {
            let requirers = deploymentToStop.requirers(in: intermediateGraph)
            let predecessors = Set(requirers.map { ConcreteOperation.stop($0, intermediateGraph) })
            
            let requirementsToStop = deploymentToStop.requirements(in: intermediateGraph).filter { deploymentsToStop.contains($0) }
            let successors = Set(requirementsToStop.map { ConcreteOperation.stop($0, intermediateGraph) })
            
            let neighbouredCommand = NeighbouredCommand(content: .stop(deploymentToStop, intermediateGraph), predecessors: predecessors, sucessors: successors)
            stopNeighbouredCommands.insert(neighbouredCommand)
            // print("New neighboured stop command added:\n\(neighbouredCommand)")
        }
        
        neighbouredCommands.formUnion(stopNeighbouredCommands)
        
        let deploymentsToAdd = targetGraph.deployments.subtracting(initialGraph.deployments)
        let deploymentsToStart = deploymentsToAdd.union(deploymentsToStop).filter { targetGraph.contains($0) }
        
        var startNeighbouredCommands: Set<NeighbouredCommand> = []
        
        // startup workflow
        for deploymentToStart in deploymentsToStart {
            let requirementsToStart = deploymentToStart.requirements(in: targetGraph).filter { deploymentsToStop.contains($0) || deploymentsToAdd.contains($0) }
            let predecessors = Set(requirementsToStart.map { ConcreteOperation.start($0, targetGraph) })
            
            let requirers = deploymentToStart.requirers(in: targetGraph)
            let successors = Set(requirers.map { ConcreteOperation.start($0, targetGraph) })
            
            let neighbouredCommand = NeighbouredCommand(content: .start(deploymentToStart, intermediateGraph), predecessors: predecessors, sucessors: successors)
            startNeighbouredCommands.insert(neighbouredCommand)
        }
        
        neighbouredCommands.formUnion(startNeighbouredCommands)
        
        let removalNeighbouredCommands = Set(deploymentsToRemove.map { NeighbouredCommand(.remove($0, intermediateGraph))})
        neighbouredCommands.formUnion(removalNeighbouredCommands)
        
        let additionNeighbouredCommands = Set(deploymentsToAdd.map { NeighbouredCommand(.add($0, intermediateGraph)) })
        neighbouredCommands.formUnion(additionNeighbouredCommands)
        
        let (stopFlows, stopNodes) = FlowSet.create(from: stopNeighbouredCommands)
        
        let stopConcreteWorkflow = ConcreteWorkflow(nodes: stopNodes, naiveFlows: stopFlows)
        stopConcreteWorkflow.groupBothEnds()
        
        let (removeFlows, removeNodes) = FlowSet.create(from: removalNeighbouredCommands)
        
        let removalConcreteWorkflow = ConcreteWorkflow(nodes: removeNodes, naiveFlows: removeFlows)
        removalConcreteWorkflow.groupBothEnds()
        
        let (addFlows, addNodes) = FlowSet.create(from: additionNeighbouredCommands)
        
        let additionConcreteWorkflow = ConcreteWorkflow(nodes: addNodes, naiveFlows: addFlows)
        additionConcreteWorkflow.groupBothEnds()
        
        let (startFlows, startNodes) = FlowSet.create(from: startNeighbouredCommands)
        
        let startConcreteWorkflow = ConcreteWorkflow(nodes: startNodes, naiveFlows: startFlows)
        startConcreteWorkflow.groupBothEnds()
        
        stopConcreteWorkflow.link(to: removalConcreteWorkflow)
        removalConcreteWorkflow.link(to: additionConcreteWorkflow)
        additionConcreteWorkflow.link(to: startConcreteWorkflow)
        
        let finalWorkflow = ConcreteWorkflow(
            nodes:
                stopConcreteWorkflow.nodes
                .union(removalConcreteWorkflow.nodes)
                .union(additionConcreteWorkflow.nodes)
                .union(startConcreteWorkflow.nodes),
            flows:
                stopConcreteWorkflow.flows
                .union(removalConcreteWorkflow.flows)
                .union(additionConcreteWorkflow.flows)
                .union(startConcreteWorkflow.flows)
        )
        
        finalWorkflow.wrap()
        finalWorkflow.calculateFlows()
        
        self.init(nodes: finalWorkflow.nodes, flows: finalWorkflow.flows, initialGraph: initialGraph, targetGraph: targetGraph)
        
        if !self.isCompliant {
            print("[CestrumCore:Warning] The constructed concrete workflow is not compliant with the BPMN standard, therefore, it cannot be run; this should not really happen, so please contact the developer")
        }
    }
    
    private func calculateFlows() {
        var result = FlowSet()
        for node in self.nodes {
            for outgoingNode in node.outgoingNodes {
                let flow = Flow(source: node, target: outgoingNode)
                result.insert(flow)
            }
        }
        self.flows = result
    }
    
    var independentNodes: NodeSet {
        return self.nodes.filter { $0.incomingNodes.isEmpty && $0.outgoingNodes.isEmpty }
    }
    
    var initialNodes: NodeSet {
        return self.nodes.filter { $0.incomingNodes.isEmpty }
    }
    
    var finalNodes: NodeSet {
        return self.nodes.filter { $0.outgoingNodes.isEmpty }
    }
    
    var isCompliant: Bool {
        return self.nonCompliantNodes.isEmpty
    }
    
    var nonCompliantNodes: NodeSet {
        return self.nodes.filter { !$0.isCompliant }
    }
    
    func groupInitialNodes() {
        let initialNodes = self.initialNodes
        guard initialNodes.count > 1 else {
            // print("No group can be made for only one (or no) initial node")
            return
        }
        let parallelSplit = Node(.split)
        parallelSplit.link(to: initialNodes)
        self.nodes.insert(parallelSplit)
        calculateFlows()
    }
    
    func groupFinalNodes() {
        let finalNodes = self.finalNodes
        guard finalNodes.count > 1 else {
            // print("No group can be made for only one (or no) final node")
            return
        }
        let parallelJoin = Node(.join)
        _ = finalNodes.map { node in
            node.link(to: parallelJoin)
        }
        self.nodes.insert(parallelJoin)
        calculateFlows()
    }
    
    func groupBothEnds() {
        self.groupInitialNodes()
        self.groupFinalNodes()
    }
    
    /// Wraps the workflow, making it start with an initial event node, and end with a final event node.
    func wrap() {
        guard initialNodes.count == 1, let firstNode = initialNodes.first else {
            print("The workflow cannot be wrapped because there are more than one 'first' nodes; please group them first")
            return
        }
        
        guard !firstNode.content.isEvent(specifically: .initial) else {
            print("The workflow cannot be wrapped with an initial node because it already starts with one")
            return
        }
        
        guard finalNodes.count == 1, let lastNode = finalNodes.first else {
            print("The workflow cannot be wrapped because there are more than one 'last' nodes; please group them first")
            return
        }
        
        guard !lastNode.content.isEvent(specifically: .final) else {
            print("The workflow cannot be wrapped with a final node because it already ends with one")
            return
        }
        
        let initialNode = Node(.initial)
        let finalNode = Node(.final)
        
        initialNode.link(to: firstNode)
        lastNode.link(to: finalNode)
        
        self.nodes.insert(initialNode)
        self.nodes.insert(finalNode)
        calculateFlows()
    }
    
    var isEmpty: Bool {
        return self.nodes.isEmpty
    }
    
    func link(to nextWorkflow: ConcreteWorkflow) {
        guard !self.isEmpty else {
            return
        }
        
        guard self.finalNodes.count == 1,
              let lastNode = self.finalNodes.first,
                !lastNode.content.isEvent(specifically: .final)
        else {
            print("The first workflow cannot be linked the other because it ends with a final node, or has many 'last' nodes; this should not happen")
            return
        }
        
        guard !nextWorkflow.isEmpty else {
            return
        }
        
        guard nextWorkflow.initialNodes.count == 1,
              let firstNode = nextWorkflow.initialNodes.first,
              !firstNode.content.isEvent(specifically: .initial) else {
            print("The other workflow cannot be linked to because it start with an initial node, or has many 'first' nodes; this should not happen")
            return
        }
        
        guard self.nodes.intersection(nextWorkflow.nodes) == [] else {
            print("Found at least one shared node between the two graphs; linking cannot be done")
            return
        }
        
        lastNode.link(to: firstNode)
        
        // FIXME: THIS STILL NEEDS SOME CLEANUP
        
        return
    }
    
    /// Runs the workflow asynchronously (requires macOS 13 or later).
    @available(macOS 13.0, *)
    public func apply(on graph: DependencyGraph, forTesting: Bool = false, stdout: FileHandle? = .standardOutput, stderr: FileHandle? = .standardError) async throws {
        guard initialNodes.count == 1,
              let initialNode = initialNodes.first,
              initialNode.content.isEvent(specifically: .initial) else {
            print("Cannot run because the initial node is either not unique or does not exist, or not specifically an 'initial' event node.")
            throw RuntimeError.nonCompliantConcreteWorkflow
        }
        
        guard self.isCompliant else {
            throw RuntimeError.nonCompliantConcreteWorkflow
        }
        
        await initialNode.receiveTokens(1)
        await initialNode.run(forTesting: forTesting, stdout: stdout, stderr: stderr)
        
        guard let targetGraph, self.initialGraph != nil else {
            fatalError("No initial or target graph were given; this shouldn't happen")
        }
        
        graph.deployments = targetGraph.deployments
        graph.dependencies = targetGraph.dependencies
    }
}

extension ConcreteWorkflow: TranslatableIntoDOT {
    public var dotTranslation: String {
        var translation = "// dot code for concrete workflow BPMN automatically generated by Cestrum"
            .addingNewLine("digraph ConcreteWorkflowBPMN {", indented: false)
            .addingNewLine("rankdir=TB;")
            .addingNewLine("bgcolor=white;")
            .addingNewLine("nodesep=0.5;")
            .addingNewLine("graph [dpi=300];")
        
        translation.addNewLine("// Event nodes")
        
        for node in self.nodes where (node.content == .initial || node.content == .final) {
            translation.addNewLine(node.dotTranslation)
        }
        
        translation.addNewLine("// Parallel gateways")
        
        for node in self.nodes where (node.content == .split || node.content == .join) {
            translation.addNewLine(node.dotTranslation)
        }
        
        translation.addNewLine("// Tasks")
        translation.addNewLine(Node.dotDefinition)
        
        for node in self.nodes {
            if case .task = node.content {
                translation.addNewLine(node.dotTranslation)
            }
        }
        
        translation.addNewLine("// Flows")
        
        for flow in self.flows {
            translation.addNewLine(flow.dotTranslation)
        }
        
        translation.addNewLine("}", indented: false)
        
        return translation
    }
}
