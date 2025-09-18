//
//  ComplementaryInformation.swift
//  CestrumCore
//
//  Created by Wadÿe on 17/09/2025.
//

import Foundation

/// Represents complementary information that can be used for more or less specific situations.
enum ComplementaryInformation: Hashable {
    case replacement(oldDeployment: String, newDeployment: String)
}
