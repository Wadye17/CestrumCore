//
//  NeighbouredCommand.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

/// Represents a tuplen (triple) consisiting of the subject (command), a set of predecessor commands, and a set of successor commands. Used for representing order between commands.
final class NeighbouredCommand: Hashable, CustomStringConvertible {
    let content: AtomicCommand
    let predecessors: Set<AtomicCommand>
    let successors: Set<AtomicCommand>
    
    init(_ content: AtomicCommand) {
        self.content = content
        self.predecessors = []
        self.successors = []
    }
    
    init(content: AtomicCommand, predecessors: Set<AtomicCommand>, sucessors: Set<AtomicCommand>) {
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
    func being(_ command: AtomicCommand) -> NeighbouredCommand? {
        self.first(where: { $0.content == command })
    }
    
    func havingInPredecessors(_ command: AtomicCommand) -> Self {
        self.filter { $0.predecessors.contains(command) }
    }
    
    func havingInSuccessors(_ command: AtomicCommand) -> Self {
        self.filter { $0.successors.contains(command) }
    }
}
