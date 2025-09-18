//
//  OrderingConstraint.swift
//  CestrumCore
//
//  Created by Wadÿe on 16/09/2025.
//

import Foundation

/// A source-target pair that expresses the precedence between two concrete operations.
///
/// For the ordering constraint `(o1, o2)`, the concrete operation `o1` must come before the concrete operation `o2`.
struct OrderingConstraint: Hashable {
    let source: ConcreteOperation
    let target: ConcreteOperation
    
    /// Creates a new ordering constraint.
    init(_ source: ConcreteOperation, _ target: ConcreteOperation) {
        self.source = source
        self.target = target
    }
}

