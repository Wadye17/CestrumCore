//
//  CESPInterpreter.swift
//  CestrumKit
//
//  Created by Wadÿe on 14/03/2025.
//

import Foundation

public struct CESPInterpreter {
    private init() { }
    
    public static func interpret(code: String) -> (graphName: String, abstractPlan: AbstractPlan) {
        let lexer = CESPLexer(input: code)
        var tokens = try! lexer.tokenise()
        tokens = tokens.filter { $0.kind.isDisposable }
        let analyser = CESPAnalyser(tokens: tokens)
        analyser.analyse()
        let translator = CESPTranslator(tokens: tokens)
        let (graphName, abstractPlan) = translator.translate()
        return (graphName, abstractPlan)
    }
}
