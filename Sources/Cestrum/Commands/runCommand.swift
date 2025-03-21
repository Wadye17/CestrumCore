//
//  runCommand.swift
//  Cestrum
//
//  Created by Wadÿe on 14/03/2025.
//

import Foundation

#if canImport(AppKit)
import AppKit
#endif

/// Runs the given command.
public func runCommand(
    _ command: String,
    stdout: FileHandle? = .standardOutput,
    stderr: FileHandle? = .standardError
) {
    let process = Process()
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", command]
    process.standardOutput = stdout
    process.standardError = stderr
    process.launch()
    process.waitUntilExit()
}
