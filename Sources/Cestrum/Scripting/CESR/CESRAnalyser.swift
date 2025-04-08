//
//  CESRAnalyser.swift
//  Cestrum
//
//  Created by Wadÿe on 13/03/2025.
//

import Foundation

/// A unit that verifies the syntax of the given CESR code.
struct CESRAnalyser {
    let tokens: [CESRToken]
    
    init(tokens: [CESRToken]) {
        self.tokens = tokens
    }
    
    func analyse() -> [CESRError] {
        var step = CESRLexer.Phase.hooking
        var errors: [CESRError] = []
        
        guard !tokens.isEmpty, let firstToken = tokens.first else {
            errors.append(CESRError(type: .emptyInput, at: 0))
            return errors
        }
        
        if firstToken.kind != .keyword(.hook) {
            errors.append(CESRError(type: .expectedHook, at: firstToken.line))
        }
        
        for (index, token) in tokens.enumerated() {
            guard index < tokens.count - 1 else { break }
            
            // Special treatments...
            switch token.kind {
            case .identifier:
                if !token.value.isValidVariableName {
                    errors.append(CESRError(type: .invalidIdentifier(token.value), at: token.line))
                }
            case .stringLiteral:
                switch step {
                case .adding(let complexOperationStep):
                    guard complexOperationStep == .deploy else {
                        break
                    }
                    verifyPathString(in: token)
                case .replacing(let replacementStep):
                    guard replacementStep == .new else {
                        break
                    }
                    verifyPathString(in: token)
                default:
                    break
                }
            default:
                break
            }
            
            if token.kind == .unknown {
                errors.append(CESRError(type: .unknownSymbol(token.value), at: token.line))
            }
            
            let nextToken = tokens[index + 1]
            
            if let nextExpectedTokens = token.nextFlexibleExpectations(during: step) {
                if !nextExpectedTokens.contains(nextToken.kind) {
                    errors.append(CESRError(type: .unexpectedToken(expectedTokens: Array(nextExpectedTokens), foundToken: nextToken), at: nextToken.line))
                }
            }
            
            step.update(for: nextToken)
        }
        
        return errors
        
        func verifyPathString(in token: CESRToken) {
            guard let _ = URL(string: token.value) else {
                errors.append(CESRError(type: .invalidPath, at: token.line))
                return
            }
            let fileURL = URL(fileURLWithPath: token.value)
            /* guard FileManager.default.fileExists(atPath: fileURL.path) else {
                errors.append(CESRError(type: .manifestFileDoesNotExist(path: token.value), at: token.line))
                return
            } */
            let fileExtension = fileURL.pathExtension
            guard ["yaml", "yml"].contains(fileExtension) else {
                errors.append(CESRError(type: .invalidManifestExtension(fileExtension), at: token.line))
                return
            }
        }
    }
}
