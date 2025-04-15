//
//  RuntimeError.swift
//  Cestrum
//
//  Created by Wadÿe on 14/04/2025.
//

import Foundation

/// Represents an error that can be thrown at runtime (generation of a target graph, synchronisation, etc...).
public enum RuntimeError: Error, CustomStringConvertible {
    case deploymentNotFound(name: String, configuration: String)
    case deploymentToAddAlreadyExists(name: String, configuration: String)
    case deploymentToRemoveNotFound(name: String, configuration: String)
    case deploymentToReplaceNotFound(name: String, configuration: String)
    case deploymentToBindNotFound(name: String, configuration: String)
    case deploymentToReleaseFound(name: String, configuration: String)
    case requirementNotFound(name: String, configuration: String)
    case targetConfigurationGraphContainsCycles(configuration: String)
    case unknown
    
    public var description: String {
        switch self {
        case .deploymentNotFound(let name, let configuration):
            "Deployment '\(name)' does not exist in configuration '\(configuration)'"
        case .deploymentToAddAlreadyExists(let name, let configuration):
            "Deployment '\(name)' cannot be added to configuration '\(configuration)' because it already exists; did you mean to replace it?"
        case .deploymentToRemoveNotFound(let name, let configuration):
            "Cannot remove deployment '\(name)' because it does not exist in configuration '\(configuration)'"
        case .deploymentToReplaceNotFound(let name, let configuration):
            "Cannot replace deployment '\(name)' because it does not exist in configuration '\(configuration)'"
        case .deploymentToBindNotFound(let name, let configuration):
            "Cannot bind deployment '\(name)' because it does not exist in configuration '\(configuration)'"
        case .deploymentToReleaseFound(let name, let configuration):
            "Cannot release deployment '\(name)' because it does not exist in configuration '\(configuration)'"
        case .requirementNotFound(let name, let configuration):
            "Required deployment '\(name)' does not exist in configuration '\(configuration)'"
        case .targetConfigurationGraphContainsCycles:
            "The reconfiguration can neither be planned nor applied because the target configuration would contain cycles; configurations must be asyclic"
        case .unknown:
            "An unknown runtime error has occured; please contact the developer"
        }
    }
}
