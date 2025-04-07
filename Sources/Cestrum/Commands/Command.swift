//
//  Command.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

/// Represents an instruction to perform.
public protocol Command: CustomStringConvertible { }

///// Represents an abstract intruction that can be translated.
//protocol TranslatableCommand: Command {
//    /// The type of commands that this command will be translated into.
//    associatedtype TargetTranslationCommand: Command
//    /// Returns the translation of this command into a lower-level command.
//    func translate(considering graph: DependencyGraph) -> [TargetTranslationCommand]
//}
