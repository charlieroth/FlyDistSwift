//
//  Utils.swift
//
//
//  Created by Charles Roth on 2024-06-23.
//

import Foundation

class StandardError: TextOutputStream {
    func write(_ string: String) {
        try! FileHandle.standardError.write(contentsOf: Data(string.utf8))
    }
}

class StandardOut: TextOutputStream {
    func write(_ string: String) {
        try! FileHandle.standardOutput.write(contentsOf: Data(string.utf8))
    }
}
