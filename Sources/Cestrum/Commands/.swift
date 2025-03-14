//
//  KubernetesCommand.swift
//  Cestrum
//
//  Created by Wadÿe on 14/03/2025.
//

import Foundation

struct KubernetesCommand: Command {
    let args: [String]
    
    var description: String {
        self.args.joined(separator: " ")
    }
}
