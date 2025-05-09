//
//  Flow.swift
//  CestrumCore
//
//  Created by Wadÿe on 09/05/2025.
//

import Foundation

struct Flow: Hashable, CustomStringConvertible {
    let source: Node
    let target: Node
    
    init(source: Node, target: Node) {
        self.source = source
        self.target = target
    }
    
    var description: String {
        return "(\(self.source) → \(self.target))"
    }
}

extension Flow: TranslatableIntoDOT {
    var dotTranslation: String {
        return "\(self.source.dotIdentifier) -> \(self.target.dotIdentifier);"
    }
}
