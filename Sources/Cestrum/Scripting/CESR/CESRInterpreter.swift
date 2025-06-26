//
//  CESRInterpreter.swift
//  Cestrum
//
//  Created by Wadÿe on 14/03/2025.
//

import Foundation
import OrderedCollections

/// The main unit for interpreting (lexing, analysing, and translating) code written in the CESR language.
///
/// The CESR language (short for **Ces**trum **R**econfiguration) is an interpreted language for writing
/// Kubernetes deployment reconfigurations in an abstract manner.
///
/// Deployment reconfiguration operations come in five different, abstract flavours: addition, removal, replacement, binding, and release.
///
/// The addition operation allows one to add a new deployment to the configuration.
/// ```
/// add a "path/to/manifest_a.yaml";
/// ```
/// Additionally, one can specify the requirements of the newly added deployment directly in the same line using the `requiring`
/// keyword, followed by a set of **already existing** or **newly added** deployments, denoting the requirements.
/// ```
/// add a "path/to/manifest_a.yaml" requiring {a, c};
/// ```
/// A string literal containing the absolute path to the YAML manifest file of the new deployment is required after its name.
///
/// The removal operation removes an existing (or newly added) deployment from the configuration.
/// ```
/// remove x;
/// ```
/// - Note: When removing a deployment using `remove`, all dependencies involving the deployment are also removed.
///
/// The replacement operation removes an existing (or newly added) deployment from the configuration, and adds a new deployment in its stead.
/// ```
/// replace d1 with d2 "path/to/manifest_d2.yaml";
/// ```
/// Unlike the removal operation, the replacement operation preserves the dependencies involving the old deployment, and simply updates them so that they would involve the new deployment instead.
///
/// Similarly to the addition operation, using `replace` also requires a string literal containing the absolute path to the YAML manifest file of the new deployment, and must be written after its name.
///
/// The binding operation makes an already existing, or newly added deployment depend on one, or many already existing or newly added deployments.
/// ```
/// bind b to {a, c};
/// ```
///
/// The unbind operation removes the dependencies between one deployment and a set of deployments.
/// ```
/// unbind g from {e, f, h};
/// ```
/// - Important: When using `bind` or `unbind`, the set of deployments must not be empty.
/// - Important: A string literal containing the (absolute) file path to a manifest file must be a valid URL, and must end with the extension "yaml" or "yml".
public struct CESRInterpreter {
    private init() { }
    
    /// Interprets the given CESR code and returns the graph name, the internal representation of the interpreted abstract reconfiguration operations, as well as errors and warnings.
    public static func interpret(code: String) -> Result<(graphName: String, abstractPlan: AbstractFormula), [CESRError]> {
        let lexer = CESRLexer(input: code)
        let (tokens, lexingErrors) = lexer.tokenise()
        guard lexingErrors.isEmpty else {
            return .failure(lexingErrors)
        }
        let analyser = CESRAnalyser(tokens: tokens)
        let analysisErrors = analyser.analyse()
        guard analysisErrors.isEmpty else {
            return .failure(analysisErrors)
        }
        let translator = CESRTranslator(tokens: tokens)
        let (graphName, abstractPlan) = translator.translate()
        return .success((graphName, abstractPlan))
    }
}
