//
//  CESRLexer.swift
//  Cestrum
//
//  Created by Wadÿe on 13/03/2025.
//

import Foundation

final class CESRLexer {
    private let input: String
    private var position: String.Index
    private var currentLine: Int = 1

    init(input: String) {
        self.input = input
        self.position = input.startIndex
    }

    func tokenise() throws -> [CESRToken] {
        var tokens: [CESRToken] = []

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
                tokens.append(try stringLiteralToken(line: currentLine))
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
        return tokens
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

        // Allow letters, numbers, and underscores in identifiers
        while position < input.endIndex, input[position].isLetter || input[position].isNumber || input[position] == "_" {
            value.append(input[position])
            advance()
        }

        let keywords: Set<String> = Set(CESRToken.Kind.Keyword.allCases.map { $0.rawValue })
        let kind: CESRToken.Kind = keywords.contains(value) ? .keyword(.init(rawValue: value)!) : .identifier

        return CESRToken(value, kind: kind, line: currentLine)
    }

    private func stringLiteralToken(line: Int) throws -> CESRToken {
        advance() // Skip the opening quote
        var value = ""
        
        while position < input.endIndex {
            if input[position] == "\"" {
                advance() // Skip the closing quote
                guard !value.contains("\n") else {
                    fatalError("Found a new line inside a label at line \(line); new lines are not allowed inside labels")
                    // throw TokenisationError("Fatal error: Found a new line inside a label at line \(line); new lines are not allowed inside labels")
                }
                
                return CESRToken(value, kind: .stringLiteral, line: currentLine)
            }
            value.append(input[position])
            advance()
        }
        
        // If we reach this, the string literal was not closed
        fatalError("Fatal error: Unclosed label string literal starting at line \(line); perhaps you forgot to close it with a double quotation mark?")
        // throw TokenisationError("Fatal error: Unclosed label string literal starting at line \(line); perhaps you forgot to close it with a double quotation mark?")
    }
    
    enum Phase: Equatable {
        case hooking
        case adding(ComplexOperationStep)
        case removing
        case replacing(ReplacementStep)
        case binding(ComplexOperationStep)
        case releasing(ComplexOperationStep)
        
        enum ComplexOperationStep: Equatable {
            case deploy
            case deploymentSet
        }
        
        enum ReplacementStep: Equatable {
            case old
            case new
        }
    }
}

extension CESRLexer.Phase {
    mutating func update(for token: CESRToken) {
        switch token.kind {
        case .keyword(let keyword):
            switch keyword {
            case .hook:
                self = .hooking
            case .add:
                self = .adding(.deploy)
            case .requiring:
                self = .adding(.deploymentSet)
            case .remove:
                self = .removing
            case .replace:
                self = .replacing(.old)
            case .with:
                self = .replacing(.new)
            case .bind:
                self = .binding(.deploy)
            case .to:
                self = .binding(.deploymentSet)
            case .release:
                self = .releasing(.deploy)
            case .from:
                self = .releasing(.deploymentSet)
            }
        default:
            return
        }
    }
}
