//
//  File.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

/// Represents a—runnable—node in a BPMN.
final class Node: @unchecked Sendable {
    let id: String = UUID().uuidString
    let content: NodeContent
    private(set) var outgoingNodes: Set<Node>
    private var _incomingNodes: NSHashTable<Node> = .weakObjects()
    var incomingNodes: Set<Node> { Set(self._incomingNodes.allObjects) }
    var tokens: UInt
    var requiredTokens: UInt { UInt(incomingNodes.count) }
    
    var canRun: Bool { self.tokens >= requiredTokens }
    
    /// Create a new, disconnected node.
    init(_ content: NodeContent) {
        self.content = content
        self.outgoingNodes = []
        self.tokens = 0
    }
    
    /// Returns whether this node is compliant with the BPMN standard.
    ///
    /// For example, a parallel join must have more than one incoming flows and only one outgoing flow to be considered compliant.
    var isCompliant: Bool {
        switch self.content {
        case .task(_):
            // here, we do not consider the initial and final events yet...
            return self.incomingNodes.count <= 1 && self.outgoingNodes.count <= 1
        case .initial:
            return self.incomingNodes.count == 0 && self.outgoingNodes.count == 1
        case .split:
            return self.incomingNodes.count == 1 && self.outgoingNodes.count > 1
        case .join:
            return self.incomingNodes.count > 1 && self.outgoingNodes.count == 1
        case .final:
            return self.incomingNodes.count == 1 && self.outgoingNodes.count == 0
        }
    }
    
    /// Creates a sequence flow from this (source) node to another (target) node.
    func link(to node: Node) {
        self.outgoingNodes.insert(node)
        node._incomingNodes.add(self)
    }
    
    /// Creates flows from this (source) node to one or many—a set—(target) nodes.
    func link(to nodes: Set<Node>) {
        self.outgoingNodes.formUnion(nodes)
        for node in nodes {
            node._incomingNodes.add(self)
        }
    }
    
    /// Removes the flow from this (source) node to the given (target) node.
    func unlink(from node: Node) {
        self.outgoingNodes.remove(node)
        node._incomingNodes.remove(self)
    }
    
    /// Removes the flows from this (source) node to one or many—a set—(target) nodes.
    func unlink(from nodes: Set<Node>) {
        self.outgoingNodes.subtract(nodes)
        for node in nodes {
            node._incomingNodes.remove(self)
        }
    }
    
    func receiveTokens(_ tokens: UInt, from node: Node? = nil) async {
        self.tokens += tokens
        // print("\(self) has received \(tokens) token(s)\(node == nil ? "" : " from \(node!)"); total: \(self.tokens)")
    }
    
    func consumeTokens(_ tokens: UInt) async {
        if tokens > self.tokens {
            self.tokens = 0
        } else {
            self.tokens -= tokens
        }
        // print("\(self) has consumed \(tokens) tokens(s); remaining: \(self.tokens)")
    }
    
    @available(macOS 13.0, *)
    func performCommand(forTesting: Bool = false, stdout: FileHandle? = .standardOutput, stderr: FileHandle? = .standardError) async {
        let (isTask, command) = self.content.isTask()
        guard let command, isTask else {
            return
        }
        if forTesting {
            print("- Starting \(self)...")
            let randomDuration = UInt8.random(in: 1...5)
            runCommand("sleep \(randomDuration)s")
            print("- Finished \(self) !")
        } else {
            runCommand(command.kubernetesEquivalent.joined(separator: " && "), stdout: stdout, stderr: stderr)
            print(command.doneString)
        }
    }
    
    @available(macOS 13.0, *)
    func run(forTesting: Bool = false, stdout: FileHandle? = .standardOutput, stderr: FileHandle? = .standardError) async {
        // print("Trying to run \(self)")
        guard self.canRun else {
            // print("\(self) cannot run yet... \(self.tokens)/\(self.requiredTokens)")
            return
        }
        
        await self.consumeTokens(1)
        
        await self.performCommand(forTesting: forTesting, stdout: stdout, stderr: stderr)
        
        await withTaskGroup(of: Void.self) { taskGroup in
            for successor in self.outgoingNodes {
                taskGroup.addTask {
                    await successor.receiveTokens(1, from: self)
                    await successor.run()
                }
            }
        }
    }
}

extension Node: Hashable {
    static func == (_ lhs: Node, _ rhs: Node) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        switch self.content {
        case .task(let atomicCommand):
            hasher.combine(atomicCommand.paperValue)
        default:
            hasher.combine(self.id)
        }
    }
}

extension Node: TranslatableIntoDOT {
    static let dotDefinition = "node [shape=rect, style=\"rounded,filled\", fillcolor=\"#ffffff\", fontname=\"Helvetica\", fontsize=10];"
    
    var dotIdentifier: String {
        let id = self.id.replacingOccurrences(of: "-", with: "_")
        switch self.content {
        case .task(let command):
            let commandIdentifier = command.description
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "-", with: "_")
            return "\(commandIdentifier)"
        case .initial:
            return "init_\(id)"
        case .split:
            return "split_\(id)"
        case .join:
            return "join_\(id)"
        case .final:
            return "end_\(id)"
        }
    }
    
    var dotTranslation: String {
        switch self.content {
        case .task(let command):
            return "\(self.dotIdentifier) [label=\"\(command.description)\"];"
        case .initial:
            return "\(self.dotIdentifier) [label=\"\", shape=circle, width=0.2, height=0.2, fixedsize=true, style=filled, fillcolor=\"#000000\"];"
        case .split, .join:
            return "\(self.dotIdentifier) [label=\"+\", shape=diamond, width=0.35, height=0.35, fixedsize=true, style=filled, fillcolor=\"#ffffff\", fontsize=20, fontname=\"Helvetica-Bold\"];"
        case .final:
            return "\(self.dotIdentifier) [label=\"\", shape=doublecircle, width=0.17, height=0.17, fixedsize=true, style=filled, fillcolor=\"#000000\"];"
        }
    }
}

extension Node: CustomStringConvertible {
    var description: String {
        self.content.description
    }
    
    var outgowingFlowsDescription: String {
        "\(self.description) -> {\(self.outgoingNodes.map { $0.description }.joined(separator: ", "))}"
    }
    
    var incomingAndOutgoingFlowsDescription: String {
        "{\(self.incomingNodes.map { $0.description }.joined(separator: ", "))} -> [ \(self.description) ] -> {\(self.outgoingNodes.map { $0.description }.joined(separator: ", "))}"
    }
    
    var fullDescription: String {
        "\(self.id)-\(self.outgowingFlowsDescription)"
    }
}
