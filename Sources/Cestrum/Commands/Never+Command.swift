//
//  Never+Command.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

extension Never: Command {
    typealias TargetTranslationCommand = Never
    func translate(considering graph: DependencyGraph) -> Never {
        fatalError("A little birdie told me this shouldn't happen :)")
    }
}

extension Never: @retroactive CustomStringConvertible {
    public var description: String { "Swift.NEVER" }
}
