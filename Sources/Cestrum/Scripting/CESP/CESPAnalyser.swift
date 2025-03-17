//
//  CESPAnalyser.swift
//  Cestrum
//
//  Created by Wadÿe on 13/03/2025.
//

import Foundation

struct CESPAnalyser {
    let tokens: [CESPToken]
    
    init(tokens: [CESPToken]) {
        self.tokens = tokens
    }
    
    func analyse() {
        var step = CESPLexer.Phase.hooking
        
        guard !tokens.isEmpty else {
            print("Error: Empty input")
            return
        }
        
        if tokens.first!.kind != .keyword(.hook) {
            print("Error: Expected hook")
        }
        
        for (index, token) in tokens.enumerated() {
            guard index < tokens.count - 1 else { break }
            
            // Special treatments...
            switch token.kind {
            case .identifier:
                guard token.value.isValidVariableName else {
                    print("\(token.line) Error: Invalid identifier")
                    return
                }
                
            default:
                break
            }
            
            if token.kind == .unknown {
                print("\(token.line) Error: Unknown symbol")
            }
            
            let nextToken = tokens[index + 1]
            
            if let nextExpectedTokens = token.nextFlexibleExpectations(during: step) {
                if !nextExpectedTokens.contains(nextToken.kind) {
                    print("\(token.line) Error: Expected \(nextExpectedTokens) after \(token) but found \(nextToken)")
                    return
                }
            } else {
                if nextToken == .end {
                    print("Reached end of file")
                }
            }
            
            step.update(for: nextToken)
        }
        
        print("Analysis passed!")
        return
    }
}
