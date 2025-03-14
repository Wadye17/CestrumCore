//
//  Status.swift
//  Cestrum
//
//  Created by Wadÿe on 11/03/2025.
//

import Foundation

/// Describes the state of a deployment.
public enum Status: Codable {
    /// The deployment is not operational.
    case stopped
    /// The deployment is up and running.
    case started
}

extension Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .stopped:
            "stopped"
        case .started:
            "started"
        }
    }
}
