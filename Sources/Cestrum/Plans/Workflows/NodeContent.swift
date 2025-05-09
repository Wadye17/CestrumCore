//
//  NodeContent.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

/// The possible content of a node.
enum NodeContent: Equatable, CustomStringConvertible {
    case task(AtomicCommand)
    case initial
    case split
    case join
    case final
    
    /// Returns whether this value is a task, along with the command inside; nil otherwise.
    func isTask() -> (true: Bool, command: AtomicCommand?) {
        guard case .task(let atomicCommand) = self else {
            return (false, nil)
        }
        return (true, atomicCommand)
    }
    
    func isGateway(specifically g: NodeContent? = nil) -> Bool {
        switch self {
        case .split, .join:
            if let g { g == self ? true : false } else { true }
        default:
            false
        }
    }
    
    func isEvent(specifically e: NodeContent? = nil) -> Bool {
        switch self {
        case .initial, .final:
            if let e { e == self ? true : false } else { true }
        default:
            false
        }
    }
    
    var description: String {
        switch self {
        case .task(let atomicCommand):
            "task <\(atomicCommand)>"
        case .initial:
            "initial"
        case .split:
            "split"
        case .join:
            "join"
        case .final:
            "final"
        }
    }
}
