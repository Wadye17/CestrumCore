//
//  CESPTranslator.swift
//  Cestrum
//
//  Created by Wadÿe on 14/03/2025.
//

import Foundation

struct CESPTranslator {
    let tokens: [CESPToken]
    
    init(tokens: [CESPToken]) {
        self.tokens = tokens
    }
    
    // IMPORTANT: Currently, the translator works naively; assuming the analysis was successful and the tokens are coherent (at least for now).
    func translate() -> (graphName: String, abstractPlan: AbstractPlan) {
        var graphName: String?
        var abstractPlan = AbstractPlan()
        let instructions = sliceTokens(self.tokens)
        for instruction in instructions {
            print("Entering instructions loop...")
            print(instruction)
            switch instruction[0].kind {
            case .keyword(.hook):
                print("Entering hook instruction...")
                graphName = instruction[1].value
                print("Done with hook instruction.")
            case .keyword(.add):
                let newDeployment = Deployment(instruction[1].value)
                // dont forget the YAML
                let manifestFilePath = instruction[2].value
                let requirements = extractRequirements(from: instruction)
                abstractPlan.add(.add(newDeployment, requirements: Set(requirements.map({ Deployment($0) }))))
            case .keyword(.remove):
                let deploymentToRemove = Deployment(instruction[1].value)
                abstractPlan.add(.remove(deploymentToRemove))
            case .keyword(.replace):
                let oldDeployment = Deployment(instruction[1].value)
                let newDeployment = Deployment(instruction[3].value)
                let manifestFilePath = instruction[4].value
                abstractPlan.add(.replace(oldDeployment: oldDeployment, newDeployment: newDeployment))
            default:
                fatalError("Unsupported keyword.")
            }
        }
        guard let graphName else {
            fatalError("Translated everything but the graph name has still not been resolved.")
        }
        return (graphName, abstractPlan)
    }
    
    func sliceTokens(_ tokens: [CESPToken]) -> [[CESPToken]] {
        var slices: [[CESPToken]] = []
        var currentSlice: [CESPToken] = []
        var isCollecting = false

        for token in tokens {
            // Ignore disposable tokens (whitespace, etc.)
            if token.kind.isDisposable { continue }

            // If token is a starting keyword, start a new slice
            if case .keyword(let keyword) = token.kind,
               [.hook, .add, .remove, .replace].contains(keyword) {
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
    
    func extractRequirements(from slice: [CESPToken]) -> Set<String> {
        var requirements: Set<String> = []
        var isCollecting = false

        for token in slice {
            switch token.kind {
            case .keyword(.requiring):
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


}
