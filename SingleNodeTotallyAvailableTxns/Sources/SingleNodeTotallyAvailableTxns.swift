//
//  SingleNodeTotallyAvailableTxns.swift
//
//
//  Created by Charles Roth on 2024-06-23.
//

import Foundation

@main
struct SingleNodeTotallyAvailableTxns {
    static func main() async throws {
        let stderr = StandardError()
        let node = Node()
        
        while let line = readLine(strippingNewline: true) {
            let data = line.data(using: .utf8)!
            let decoder = JSONDecoder()
            let req = try decoder.decode(MaelstromMessage.self, from: data)
            
            switch req.body {
            case .initMessage(let body):
                Task {
                    try await node.handleInit(req: req, body: body)
                }
                break
            default:
                stderr.write("no message handler for type: \(req.body.type)\n")
                break
            }
        }
    }
}

