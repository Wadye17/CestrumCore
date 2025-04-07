//
//  CESPAnalyser.swift
//  Cestrum
//
//  Created by Wadÿe on 13/03/2025.
//

import Foundation

struct CESPAnalyser {
    let tokens: [CESRToken]
    
    init(tokens: [CESRToken]) {
        self.tokens = tokens
    }
    
    func analyse() {
        var step = CESRLexer.Phase.hooking
        
        guard !tokens.isEmpty else {
            fatalError("Error: Empty input")
        }
        
        if tokens.first!.kind != .keyword(.hook) {
            fatalError("Error: Expected hook")
        }
        
        for (index, token) in tokens.enumerated() {
            guard index < tokens.count - 1 else { break }
            
            // Special treatments...
            switch token.kind {
            case .identifier:
                guard token.value.isValidVariableName else {
                    fatalError("\(String(describing: token.line)) Error: Invalid identifier")
                }
                
            default:
                break
            }
            
            if token.kind == .unknown {
                fatalError("\(String(describing: token.line)) Error: Unknown symbol")
            }
            
            let nextToken = tokens[index + 1]
            
            if let nextExpectedTokens = token.nextFlexibleExpectations(during: step) {
                if !nextExpectedTokens.contains(nextToken.kind) {
                    fatalError("\(String(describing: token.line)) Error: Expected \(nextExpectedTokens) after \(token) but found \(nextToken)")
                }
            } else {
                if nextToken == .end {
                    print("Reached end of file")
                }
            }
            
            step.update(for: nextToken)
        }
        
        // print("Analysis passed!")
        return
    }
}
