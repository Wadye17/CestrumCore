//
//  CESRToken.swift
//  Cestrum
//
//  Created by Wadÿe on 13/03/2025.
//

import Foundation

/// Represents a token in the CESR language.
final class CESRToken: Hashable, CustomStringConvertible, Sendable {
    let value: String
    let kind: Kind
    let line: Int!
    
    private init(_ value: String, kind: Kind) {
        self.value = value
        self.kind = kind
        self.line = nil
    }
    
    init(_ value: String, kind: Kind, line: Int?) {
        self.value = value
        self.kind = kind
        self.line = line
    }
    
    static let end = CESRToken("\0", kind: .end)
    
    func nextFlexibleExpectations(during phase: CESRLexer.Phase) -> Set<Kind>? {
        switch self.kind {
        case .keyword(let keyword):
            switch keyword {
            case .hook:
                return [.stringLiteral]
            case .add:
                return [.identifier]
            case .requiring:
                return [.identifier, .brace(.opening)]
            case .remove:
                return [.identifier]
            case .replace:
                return [.identifier]
            case .with:
                return [.identifier]
            case .bind:
                return [.identifier]
            case .to:
                return [.brace(.opening)]
            case .release:
                return [.identifier]
            case .from:
                return [.brace(.opening)]
            }
        case .identifier:
            switch phase {
            case .hooking:
                return nil
            case .adding(let addingStep):
                switch addingStep {
                case .deploy:
                    return [.stringLiteral]
                case .deploymentSet:
                    return [.comma, .brace(.closing)]
                }
            case .removing:
                return [.semicolon]
            case .replacing(let replacementStep):
                switch replacementStep {
                case .old:
                    return [.keyword(.with)]
                case .new:
                    return [.stringLiteral]
                }
            case .binding(let step):
                switch step {
                case .deploy:
                    return [.keyword(.to)]
                case .deploymentSet:
                    return [.comma, .brace(.closing)]
                }
            case .releasing(let step):
                switch step {
                case .deploy:
                    return [.keyword(.from)]
                case .deploymentSet:
                    return [.comma, .brace(.closing)]
                }
            }
        case .stringLiteral:
            switch phase {
            case .hooking, .replacing(_):
                return [.semicolon]
            case .adding(_):
                guard case CESRLexer.Phase.adding(.deploy) = phase else {
                    return nil
                }
                return [.semicolon, .keyword(.requiring)]
            default:
                return nil
            }
        case .comma:
            switch phase {
            case .adding(let addingStep):
                switch addingStep {
                case .deploy:
                    return nil
                case .deploymentSet:
                    return [.identifier]
                }
            default:
                return nil
            }
        case .brace(let brace):
            switch brace {
            case .opening:
                switch phase {
                case .adding(let step):
                    guard step == .deploymentSet else {
                        return nil
                    }
                    return [.identifier, .brace(.closing)]
                case .binding(let step), .releasing(let step):
                    guard step == .deploymentSet else {
                        return nil
                    }
                    return [.identifier]
                default:
                    return nil
                }
            case .closing:
                switch phase {
                case .adding(let step), .binding(let step), .releasing(let step):
                    guard step == .deploymentSet else {
                        return nil
                    }
                    return [.semicolon]
                default:
                    return nil
                }
            }
        case .semicolon:
            let instructionTokenKinds = Set(CESRToken.Kind.Keyword.instructionKeywords.map({ CESRToken.Kind.keyword($0) }))
            return instructionTokenKinds.union([.end])
        case .unknown:
            return nil
        case .end:
            return []
        default:
            return nil
        }
    }
    
    var description: String {
        switch self.kind {
        case .keyword(let keyword):
            "'\(keyword.rawValue)'"
        case .brace(let brace):
            switch brace {
            case .opening:
                "opening brace"
            case .closing:
                "closing brace"
            }
        case .comma:
            "comma"
        case .semicolon:
            "semicolon"
        case .end:
            "end of file"
        case .identifier:
            "identifier '\(value)'"
        case .stringLiteral:
            "string literal"
        case .whitespace:
            "whitespace"
        case .unknown:
            "unknown"
        }
    }
    
    static func == (_ lhs: CESRToken, _ rhs: CESRToken) -> Bool {
        lhs.value == rhs.value
        && lhs.kind == rhs.kind
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(kind)
    }
}

extension CESRToken {
    enum Kind: Hashable, CustomStringConvertible {
        case keyword(Keyword)
        case identifier
        case stringLiteral
        case comma
        case brace(Brace)
        case semicolon
        case whitespace
        case unknown
        case end
        
        var description: String {
            switch self {
            case .keyword(let keyword):
                "'\(keyword)'"
            case .identifier:
                "deployment"
            case .stringLiteral:
                "string literal"
            case .comma:
                "comma"
            case .brace(let brace):
                "'\(brace.rawValue)'"
            case .semicolon:
                "semicolon"
            case .whitespace:
                "whitespace"
            case .unknown:
                "unknown symbol"
            case .end:
                "end of code"
            }
        }
        
        var isDisposable: Bool {
            switch self {
            case .whitespace:
                return true
            default:
                return false
            }
        }
        
        enum Keyword: String, CaseIterable {
            case hook
            case add
            case requiring
            case remove
            case replace
            case with
            case bind
            case to
            case release
            case from
            
            static var instructionKeywords: Set<Keyword> {
                return [.add, .remove, .replace, .bind, .release]
            }
            
            static var setIntroductorKeywords: Set<Keyword> {
                return [.requiring, .to, .from]
            }
            
            init?(rawValue: String) {
                switch rawValue {
                case "hook":
                    self = .hook
                case "add":
                    self = .add
                case "requiring":
                    self = .requiring
                case "remove":
                    self = .remove
                case "replace":
                    self = .replace
                case "with":
                    self = .with
                case "bind":
                    self = .bind
                case "to":
                    self = .to
                case "release":
                    self = .release
                case "from":
                    self = .from
                default:
                    return nil
                }
            }
        }
        
        enum Brace: String {
            case opening = "{"
            case closing = "}"
            
            init?(rawValue: String) {
                switch rawValue {
                case "{":
                    self = .opening
                case "}":
                    self = .closing
                default:
                    return nil
                }
            }
        }
    }
}
