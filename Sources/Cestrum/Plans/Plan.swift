//
//  Plan.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

protocol Plan: CustomStringConvertible {
    associatedtype Content: Command
    var lines: [Content] { get set }
    @discardableResult mutating func add(_ line: Content) -> Self
    @discardableResult mutating func add(_ lines: [Content]) -> Self
}

extension Plan {
    @discardableResult
    public mutating func add(_ line: Content) -> Self {
        self.lines.append(line)
        return self
    }
    
    @discardableResult
    public mutating func add(_ lines: [Content]) -> Self {
        self.lines.append(contentsOf: lines)
        return self
    }
}
