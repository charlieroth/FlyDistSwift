//
//  Workers.swift
//
//
//  Created by Charles Roth on 2024-06-18.
//

import Foundation
import AsyncAlgorithms

struct WorkTask {
    var id: Int
    var secondsToWorkFor: Int
}

struct WorkResult {
    var taskId: Int
    var result: Bool
}

typealias HandlerFunc = @Sendable (String) throws -> Bool

