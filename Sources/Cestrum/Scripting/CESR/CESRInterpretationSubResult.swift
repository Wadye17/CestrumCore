//
//  File.swift
//  CestrumCore
//
//  Created by Wadÿe on 08/04/2025.
//

import Foundation

struct CESRInterpretationSubResult {
    let tokens: [CESRToken]
    let errors: [CESRError]
    
    internal init(tokens: [CESRToken], errors: [CESRError]) {
        self.tokens = tokens
        self.errors = errors
    }
}
