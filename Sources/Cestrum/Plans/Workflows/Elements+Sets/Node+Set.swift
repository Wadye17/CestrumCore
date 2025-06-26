//
//  Node+Set.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

/// A set of nodes.
typealias NodeSet = Set<Node>

extension NodeSet {
    func task(having command: ConcreteOperation) -> Node? {
        self.first(where: { $0.content.isTask().command?.paperValue == command.paperValue })
    }
}
