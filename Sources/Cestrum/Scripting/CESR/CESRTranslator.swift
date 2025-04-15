//
//  CESRTranslator.swift
//  Cestrum
//
//  Created by Wadÿe on 14/03/2025.
//

import Foundation
import OrderedCollections

/// A unit responsible for translating a sequence of CESR tokens into an internal representation of reconfiguration operations.
///
/// - Important: The CESR translator may only be used **after** the analysis phase using ``CESRAnalyser``.
struct CESRTranslator {
    let tokens: [CESRToken]
    
    init(tokens: [CESRToken]) {
        self.tokens = tokens
    }
    
    // IMPORTANT: Currently, the translator works naively; assuming the analysis was successful and the tokens are coherent (at least for now).
    func translate() -> (graphName: String, abstractPlan: AbstractPlan) {
        var graphName: String?
        var abstractPlan = AbstractPlan()
        let instructions = sliceTokens(self.tokens)
        for instruction in instructions {
            switch instruction[0].kind {
            case .keyword(.hook):
                graphName = instruction[1].value
            case .keyword(.add):
                let deploymentName = instruction[1].value
                // dont forget the YAML
                let manifestPath = instruction[2].value
                let newDeployment = Deployment(deploymentName, manifestPath: manifestPath)
                let requirements = extractDeploymentSet(from: instruction)
                abstractPlan.add(.add(newDeployment, requirements: requirements))
            case .keyword(.remove):
                let nameOfDeploymentToRemove = instruction[1].value
                abstractPlan.add(.remove(nameOfDeploymentToRemove))
            case .keyword(.replace):
                let oldDeploymentName = instruction[1].value
                let newDeploymentName = instruction[3].value
                let newDeploymentManifestPath = instruction[4].value
                let newDeployment = Deployment(newDeploymentName, manifestPath: newDeploymentManifestPath)
                abstractPlan.add(.replace(oldDeploymentName: oldDeploymentName, newDeployment: newDeployment))
            case .keyword(.bind):
                let deploymentName = instruction[1].value
                let requirementsNames = extractDeploymentSet(from: instruction)
                abstractPlan.add(.bind(deploymentName: deploymentName, requirementsNames: requirementsNames))
            case .keyword(.release):
                let deploymentName = instruction[1].value
                let otherDeployments = extractDeploymentSet(from: instruction)
                abstractPlan.add(.release(deploymentName: deploymentName, otherDeploymentsNames: otherDeployments))
            default:
                print("UNEXPECTED: Unsupported line type '\(instruction)'")
            }
        }
        guard let graphName else {
            fatalError("Translated everything, but the graph name has still not been resolved")
        }
        
        let sortedLines = OrderedSet(abstractPlan.lines.sorted(by: { $0.priority > $1.priority }))
        _ = consume abstractPlan
        var sortedAbstractPlan = AbstractPlan(with: sortedLines)
        var deploymentsToBeReplaced = [String : String]()
        for (index, var line) in sortedAbstractPlan.lines.enumerated() {
            switch line {
            case .add(let deployment, var requirementsNames):
                for requirementName in requirementsNames {
                    if let replacementOfRequirement = deploymentsToBeReplaced[requirementName] {
                        requirementsNames.remove(requirementName)
                        requirementsNames.insert(replacementOfRequirement)
                    }
                }
                line = .add(deployment, requirements: requirementsNames)
            case .remove(let deploymentName):
                if let replacement = deploymentsToBeReplaced[deploymentName] {
                    line = .remove(replacement)
                }
            case .replace(let oldDeploymentName, let newDeployment):
                deploymentsToBeReplaced[oldDeploymentName] = newDeployment.name
            case .bind(let deploymentName, var requirementsNames):
                if let replacement = deploymentsToBeReplaced[deploymentName] {
                    for requirementName in requirementsNames {
                        if let replacementOfRequirement = deploymentsToBeReplaced[requirementName] {
                            requirementsNames.remove(requirementName)
                            requirementsNames.insert(replacementOfRequirement)
                        }
                    }
                    sortedAbstractPlan.lines.remove(line)
                    line = .bind(deploymentName: replacement, requirementsNames: requirementsNames)
                    sortedAbstractPlan.lines.insert(line, at: index)
                } else {
                    for requirementName in requirementsNames {
                        if let replacementOfRequirement = deploymentsToBeReplaced[requirementName] {
                            requirementsNames.remove(requirementName)
                            requirementsNames.insert(replacementOfRequirement)
                        }
                    }
                    sortedAbstractPlan.lines.remove(line)
                    line = .bind(deploymentName: deploymentName, requirementsNames: requirementsNames)
                    sortedAbstractPlan.lines.insert(line, at: index)
                }
            case .release(let deploymentName, var otherDeploymentsNames):
                if let replacement = deploymentsToBeReplaced[deploymentName] {
                    for otherDeploymentName in otherDeploymentsNames {
                        if let replacementOfOtherDeployment = deploymentsToBeReplaced[otherDeploymentName] {
                            otherDeploymentsNames.remove(otherDeploymentName)
                            otherDeploymentsNames.insert(replacementOfOtherDeployment)
                        }
                    }
                    sortedAbstractPlan.lines.remove(line)
                    line = .release(deploymentName: replacement, otherDeploymentsNames: otherDeploymentsNames)
                    sortedAbstractPlan.lines.insert(line, at: index)
                } else {
                    for otherDeploymentName in otherDeploymentsNames {
                        if let replacementOfOtherDeployment = deploymentsToBeReplaced[otherDeploymentName] {
                            otherDeploymentsNames.remove(otherDeploymentName)
                            otherDeploymentsNames.insert(replacementOfOtherDeployment)
                        }
                    }
                    sortedAbstractPlan.lines.remove(line)
                    line = .release(deploymentName: deploymentName, otherDeploymentsNames: otherDeploymentsNames)
                    sortedAbstractPlan.lines.insert(line, at: index)
                }
            }
        }
        return (graphName, sortedAbstractPlan)
    }
    
    func sliceTokens(_ tokens: [CESRToken]) -> [[CESRToken]] {
        var slices: [[CESRToken]] = []
        var currentSlice: [CESRToken] = []
        var isCollecting = false

        for token in tokens {
            // Ignore disposable tokens (whitespace, etc.)
            if token.kind.isDisposable { continue }

            // If token is a starting keyword, start a new slice
            if case .keyword(let keyword) = token.kind,
               [.hook, .add, .remove, .replace, .bind, .release].contains(keyword) {
                // If we were collecting, store the previous slice
                if !currentSlice.isEmpty {
                    slices.append(currentSlice)
                    currentSlice = []
                }
                isCollecting = true
            }

            // If we are collecting, add tokens to the slice
            if isCollecting {
                currentSlice.append(token)
            }

            // If token is a semicolon, stop collecting
            if token.kind == .semicolon {
                isCollecting = false
                slices.append(currentSlice)
                currentSlice = []
            }
        }

        return slices
    }
    
    func extractDeploymentSet(from slice: [CESRToken]) -> Set<String> {
        var requirements: Set<String> = []
        var isCollecting = false

        for token in slice {
            switch token.kind {
            case .keyword(.requiring), .keyword(.to), .keyword(.from):
                isCollecting = true  // Start collecting after "requiring"
            case .brace(.opening):
                continue  // Ignore the opening brace "{"
            case .brace(.closing):
                break  // Stop collecting at "}"
            case .identifier where isCollecting:
                requirements.insert(token.value)  // Add identifiers to the set
            case .comma:
                continue  // Ignore commas
            default:
                if isCollecting { break }  // Stop collecting on unexpected token
            }
        }

        return requirements
    }

    struct Replacement: Hashable {
        let old: String
        let new: String
    }
}

extension Set where Element == CESRTranslator.Replacement {
    func old(of name: String) -> String? {
        return self.first(where: { $0.new == name })?.old
    }
    
    func new(of name: String) -> String? {
        return self.first(where: { $0.old == name })?.new
    }
}

extension Dictionary where Value: Equatable {
    func someKey(forValue val: Value) -> Key? {
        return first(where: { $1 == val })?.key
    }
}
