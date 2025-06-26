//
//  CESRLexer.swift
//  Cestrum
//
//  Created by Wadÿe on 13/03/2025.
//

import Foundation

/// A unit which decomposes a code written in CESR language into separate tokens.
final class CESRLexer {
    private let input: String
    private var position: String.Index
    private var currentLine: Int = 1
    private var currentColumn: Int = 1

    init(input: String) {
        self.input = input
        self.position = input.startIndex
    }

    func tokenise() -> (tokens: [CESRToken], errors: [CESRError]) {
        var tokens: [CESRToken] = []
        var errors: [CESRError] = []

        while position < input.endIndex {
            let currentChar = input[position]

            if currentChar.isWhitespace {
                if currentChar == "\n" {
                    currentLine += 1
                }
                tokens.append(CESRToken(String(currentChar), kind: .whitespace, line: currentLine))
                advance()
            } else if currentChar.isLetter {
                tokens.append(identifierOrKeywordToken())
            } else if currentChar == "\"" {
                if let stringLiteralToken = stringLiteralToken(line: currentLine, errors: &errors) {
                    tokens.append(stringLiteralToken)
                }
            } else if isSymbol(currentChar) {
                let kind: CESRToken.Kind
                switch currentChar {
                case ",":
                    kind = .comma
                case ";":
                    kind = .semicolon
                case "{":
                    kind = .brace(.opening)
                case "}":
                    kind = .brace(.closing)
                default:
                    kind = .unknown
                }
                tokens.append(CESRToken(String(currentChar), kind: kind, line: currentLine))
                advance()
            } else if currentChar.isNumber {
                tokens.append(CESRToken(String(currentChar), kind: .unknown, line: currentLine))
            } else {
                tokens.append(CESRToken(String(currentChar), kind: .unknown, line: currentLine))
                advance()
            }
        }
        tokens.append(.end)
        
        tokens = tokens.filter { !$0.kind.isDisposable }
        return (tokens, errors)
    }

    private func advance() {
        position = input.index(after: position)
    }

    private func peekNext() -> Character? {
        let nextPosition = input.index(after: position)
        return nextPosition < input.endIndex ? input[nextPosition] : nil
    }

    private func isSymbol(_ char: Character) -> Bool {
        let symbols: Set<Character> = [";", ",", "{", "}"]
        return symbols.contains(char)
    }
    
    private func isOpeningBrace(_ char: Character) -> (Bool, CESRToken.Kind.Brace) {
        let braces: Set<Character> = ["{", "}"]
        return (braces.contains(char), .init(rawValue: String(char))!)
    }

    private func identifierOrKeywordToken() -> CESRToken {
        var value = ""

        // Allow letters, numbers, and underscores in identifiers...
        while position < input.endIndex, input[position].isLetter || input[position].isNumber || input[position] == "_" || input[position] == "-" {
            value.append(input[position])
            advance()
        }

        let keywords: Set<String> = Set(CESRToken.Kind.Keyword.allCases.map { $0.rawValue })
        let kind: CESRToken.Kind = keywords.contains(value) ? .keyword(.init(rawValue: value)!) : .identifier

        return CESRToken(value, kind: kind, line: currentLine)
    }

    private func stringLiteralToken(line: Int, errors: inout [CESRError]) -> CESRToken? {
        advance() // Skip the opening quote...
        var value = ""
        
        while position < input.endIndex {
            if input[position] == "\"" {
                advance() // Skip the closing quote
                guard !value.contains("\n") else {
                    errors.append(CESRError(type: .multilineString, at: line))
                    return nil
                }
                
                return CESRToken(value, kind: .stringLiteral, line: currentLine)
            }
            value.append(input[position])
            advance()
        }
        
        // If we reach this, the string literal was not closed
        errors.append(CESRError(type: .unclosedStringLiteral(firstLine: line), at: line))
        return nil
    }
    
    enum Context: Equatable {
        case beginning
        case hooking
        case adding(ComplexOperationStep)
        case removing
        case replacing(ReplacementStep)
        case binding(ComplexOperationStep)
        case releasing(ComplexOperationStep)
        case `break`
        case unknown
        
        enum ComplexOperationStep: Equatable {
            case deploy
            case deploymentSet
        }
        
        enum ReplacementStep: Equatable {
            case old
            case new
        }
        
        var messageInterpolationDescription: String {
            switch self {
            case .hooking:
                "hooking a configuration"
            case .adding(_):
                "'add' operations"
            case .removing:
                "'remove' operation"
            case .replacing(_):
                "'replace' operation"
            case .binding(_):
                "'bind' operation"
            case .releasing(_):
                "'release' operation"
            case .beginning:
                "<begining>"
            case .unknown:
                "<unknown context>"
            case .break:
                "<break>"
            }
        }
    }
}

extension CESRLexer.Context {
    mutating func update(for token: CESRToken) {
        switch token.kind {
        case .keyword(let keyword):
            switch keyword {
            case .configuration:
                guard self == .beginning else {
                    return
                }
                self = .hooking
            case .add:
                self = .adding(.deploy)
            case .requiring:
                guard self == .adding(.deploy) else {
                    return
                }
                self = .adding(.deploymentSet)
            case .remove:
                self = .removing
            case .replace:
                self = .replacing(.old)
            case .with:
                guard self == .replacing(.old) else {
                    return
                }
                self = .replacing(.new)
            case .bind:
                self = .binding(.deploy)
            case .to:
                guard self == .binding(.deploy) else {
                    return
                }
                self = .binding(.deploymentSet)
            case .unbind:
                self = .releasing(.deploy)
            case .from:
                guard self == .releasing(.deploy) else {
                    return
                }
                self = .releasing(.deploymentSet)
            }
        case .semicolon:
            self = .break
        default:
            return
        }
    }
}
