//
//  StringProtocol+Capitalised.swift
//  CestrumCore
//
//  Created by Wadÿe on 10/04/2025.
//

import Foundation

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstCapitalised: String { prefix(1).capitalized + dropFirst() }
}
