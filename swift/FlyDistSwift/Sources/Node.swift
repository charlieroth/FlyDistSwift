//
//  Node.swift
//
//
//  Created by Charlie Roth on 2024-05-28.
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

actor Node {
    var stderr: StandardError
    var stdout: StandardOut
    
    var id: String? = nil
    var nodes: [String]? = nil
    var messages: [Int] = []
    var topology: [String:[String]]? = nil
    
    init(stderr: StandardError, stdout: StandardOut) {
        self.stderr = stderr
        self.stdout = stdout
    }
}
