//
//  NeighbouredCommand.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

/// Represents a tuplen (triple) consisiting of the subject (command), a set of predecessor commands, and a set of successor commands. Used for representing order between commands.
final class NeighbouredCommand: Hashable, CustomStringConvertible {
    let content: ConcreteOperation
    let predecessors: Set<ConcreteOperation>
    let successors: Set<ConcreteOperation>
    
    init(_ content: ConcreteOperation) {
        self.content = content
        self.predecessors = []
        self.successors = []
    }
    
    init(content: ConcreteOperation, predecessors: Set<ConcreteOperation>, sucessors: Set<ConcreteOperation>) {
        self.content = content
        self.predecessors = predecessors
        self.successors = sucessors
    }
    
    static func == (_ lhs: NeighbouredCommand, _ rhs: NeighbouredCommand) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(predecessors)
        hasher.combine(successors)
    }
    
    var description: String {
        "{\(predecessors), \(content), \(successors)}"
    }
}

extension Set<NeighbouredCommand> {
    func being(_ command: ConcreteOperation) -> NeighbouredCommand? {
        self.first(where: { $0.content == command })
    }
    
    func havingInPredecessors(_ command: ConcreteOperation) -> Self {
        self.filter { $0.predecessors.contains(command) }
    }
    
    func havingInSuccessors(_ command: ConcreteOperation) -> Self {
        self.filter { $0.successors.contains(command) }
    }
}
