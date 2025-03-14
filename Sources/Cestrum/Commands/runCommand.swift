//
//  runCommand.swift
//  CestrumKit
//
//  Created by Wadÿe on 14/03/2025.
//

import Foundation

#if canImport(AppKit)
import AppKit
#endif

/// Runs the given command.
public func runCommand(_ command: String) {
    let process = Process()
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", command]
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError
    process.launch()
    process.waitUntilExit()
}
