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
        var context = CESRLexer.Context.beginning
        var errors: [CESRError] = []
        
        guard !tokens.isEmpty, let firstToken = tokens.first else {
            errors.append(CESRError(type: .emptyInput))
            return errors
        }
        
        if firstToken.kind != .keyword(.hook) {
            errors.append(CESRError(type: .expectedHook, at: firstToken.line))
        }
        
        for (index, token) in tokens.enumerated() {
            context.update(for: token)
            
            guard index < tokens.count - 1 else { break }
            
            // Special treatments...
            switch token.kind {
            case .identifier:
                if !token.value.isValidVariableName {
                    errors.append(CESRError(type: .invalidIdentifier(token.value), at: token.line))
                }
            case .stringLiteral:
                print("Found a string literal '\(token.value)'")
                print(context)
                guard context == .hooking || context == .adding(.deploy) || context == .replacing(.new) else {
                    break
                }
                guard !token.value.isEmpty else {
                    errors.append(CESRError(type: .emptyStringLiteral, at: token.line))
                    break
                }
                switch context {
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
            case .unknown:
                errors.append(CESRError(type: .unknownSymbol(token.value), at: token.line))
            default:
                break
            }
            
            let nextToken = tokens[index + 1]
            
            if let nextExpectedTokens = token.nextFlexibleExpectations(during: context) {
                if !nextExpectedTokens.contains(nextToken.kind) {
                    if context == .break {
                        errors.append(CESRError(type: .unwelcomeToken(nextToken), at: nextToken.line))
                    } else if token.kind == .semicolon {
                        errors.append(CESRError(type: .expectedOperationOrEnd(foundToken: nextToken), at: token.line))
                    } else if nextExpectedTokens.count == 1 && nextExpectedTokens.first! == .semicolon {
                        errors.append(CESRError(type: .expectedSemicolon, at: token.line))
                    } else {
                        errors.append(CESRError(type: .unexpectedToken(expectedTokens: Array(nextExpectedTokens), foundToken: nextToken), at: token.line))
                    }
                }
            } else {
                // errors.append(CESRError(type: .unwelcomeToken(nextToken), at: nextToken.line))
            }
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
