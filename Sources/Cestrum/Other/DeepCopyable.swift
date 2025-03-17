//
//  DeepCopyable.swift
//  Cestrum
//
//  Created by Wadÿe on 12/03/2025.
//

import Foundation

/// A type that can create an exact copy of itself as a separate instance.
protocol DeepCopyable: AnyObject, Codable {
    /// Create an exact copy of this object as a separate instance.
    func createCopy() -> Self
}

extension DeepCopyable {
    func createCopy() -> Self {
        guard let jsonCopy = try? JSONEncoder.default.encode(self) else {
            fatalError("Failed to create an instance copy for \(Self.self)")
        }
        
        guard let newInstance = try? JSONDecoder.default.decode(Self.self, from: jsonCopy) else {
            fatalError("Failed to decode the instance copy for \(Self.self)")
        }
        
        return newInstance
    }
}

extension JSONEncoder {
    /// Default instance of a JSON encoder.
    static let `default` = JSONEncoder()
}

extension JSONDecoder {
    /// Default instance of a JSON decoder.
    static let `default` = JSONDecoder()
}
