//
//  CESPToken.swift
//  Cestrum
//
//  Created by Wadÿe on 13/03/2025.
//

import Foundation

final class CESPToken: Hashable, CustomStringConvertible {
    let value: String
    var kind: Kind
    let line: Int?
    
    init(_ value: String, kind: Kind) {
        self.value = value
        self.kind = kind
        self.line = nil
    }
    
    init(_ value: String, kind: Kind, line: Int?) {
        self.value = value
        self.kind = kind
        self.line = line
    }
    
    nonisolated(unsafe) static let end = CESPToken("\0", kind: .end)
    
    func nextFlexibleExpectations(during phase: CESPLexer.Phase) -> Set<Kind>? {
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
            }
        case .identifier:
            switch phase {
            case .hooking:
                return nil
            case .adding(let addingStep):
                switch addingStep {
                case .deploy:
                    return [.stringLiteral]
                case .requirements:
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
            }
        case .stringLiteral:
            switch phase {
            case .hooking, .replacing(_):
                return [.semicolon]
            case .adding(_):
                guard case CESPLexer.Phase.adding(.deploy) = phase else {
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
                case .requirements:
                    return [.identifier]
                }
            default:
                return nil
            }
        case .brace(let brace):
            switch brace {
            case .opening:
                guard case CESPLexer.Phase.adding(.requirements) = phase else {
                    return nil
                }
                return [.identifier, .brace(.closing)]
            case .closing:
                guard case CESPLexer.Phase.adding(.requirements) = phase else {
                    return nil
                }
                return [.semicolon]
            }
        case .semicolon:
            return [.keyword(.add), .keyword(.remove), .keyword(.replace), .end]
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
    
    static func == (_ lhs: CESPToken, _ rhs: CESPToken) -> Bool {
        lhs.value == rhs.value
        && lhs.kind == rhs.kind
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(kind)
    }
}

extension CESPToken {
    enum Kind: Hashable {
        case keyword(Keyword)
        case identifier
        case stringLiteral
        case comma
        case brace(Brace)
        case semicolon
        case whitespace
        case unknown
        case end
        
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
