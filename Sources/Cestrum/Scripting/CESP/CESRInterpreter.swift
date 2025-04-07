//
//  CESRInterpreter.swift
//  Cestrum
//
//  Created by Wadÿe on 14/03/2025.
//

import Foundation

public struct CESRInterpreter {
    private init() { }
    
    public static func interpret(code: String) -> (graphName: String, abstractPlan: AbstractPlan) {
        let lexer = CESRLexer(input: code)
        var tokens = try! lexer.tokenise()
        tokens = tokens.filter { !$0.kind.isDisposable }
        let analyser = CESPAnalyser(tokens: tokens)
        analyser.analyse()
        let translator = CESRTranslator(tokens: tokens)
        let (graphName, abstractPlan) = translator.translate()
        return (graphName, abstractPlan)
    }
}
