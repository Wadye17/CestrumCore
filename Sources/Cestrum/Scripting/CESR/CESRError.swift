//
//  CESRError.swift
//  CestrumCore
//
//  Created by Wadÿe on 08/04/2025.
//

import Foundation

enum CESRInterpretationErrorKind: LocalizedError {
    case emptyInput
    case expectedHook
    case unexpectedToken(expectedTokens: [CESRToken.Kind], foundToken: CESRToken)
    case invalidIdentifier(String)
    case unknownSymbol(String)
    case emptyStringLiteral
    case multilineString
    case unclosedStringLiteral(firstLine: Int)
    case invalidPath
    case manifestFileDoesNotExist(path: String)
    case invalidManifestExtension(String)
    case emptySet(CESRLexer.Phase)
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            "Empty input"
        case .expectedHook:
            "Expected hooking; CESR code must start with a 'hook' operation"
        case .unexpectedToken(let expectedTokens, let foundToken):
            "Excpected \(expectedTokens.map(\.description).joined(separator: ", or ")); but found \(foundToken)"
        case .invalidIdentifier(let value):
            "Invalid identifier '\(value)'"
        case .unknownSymbol(let value):
            "Unknown symbol '\(value)'"
        case .emptyStringLiteral:
            "Empty string literal"
        case .multilineString:
            "Multiline string literals are not allowed"
        case .unclosedStringLiteral(let firstLine):
            "Unclosed multiline string literal starting at line \(firstLine); did you mean to close it with a double quotation mark?"
        case .invalidPath:
            "Invalid path provided; a path string literal must be a valid URL"
        case .manifestFileDoesNotExist(let path):
            "Manifest file at \(path) does not exist"
        case .invalidManifestExtension(let ext):
            "Invalid manifest file extension '.\(ext)'; supported extensions are '.yaml' and '.yml'"
        case .emptySet(let phase):
            "Deployment sets must not be empty in a \(phase.messageInterpolationDescription)"
        }
    }
}

/// Represents a textual interpretation error with a line.
public struct CESRError: LocalizedError, Hashable {
    public let line: Int?
    public let message: String
    
    /// Creates an instance of a lined error.
    init(type: CESRInterpretationErrorKind, at line: Int? = nil) {
        self.line = line
        self.message = type.errorDescription ?? "Unknown error; please contact the developer, as this should not happen"
    }
    
    private init(_ message: String, at line: Int? = nil) {
        self.line = nil
        self.message = message
    }
    
    static func custom(_ message: String, at line: Int?) -> CESRError {
        return CESRError(message, at: line)
    }
}

extension Array: @retroactive Error where Element == CESRError { }
