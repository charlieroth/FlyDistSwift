//
//  SingleNodeKafka.swift
//
//
//  Created by Charles Roth on 2024-06-19.
//

import Foundation

@main
struct SingleNodeKafka {
    static func main() async throws {
        let stderr = StandardError()
        let node = Node()
        
        while let line = readLine(strippingNewline: true) {
            let data = line.data(using: .utf8)!
            let decoder = JSONDecoder()
            let req = try decoder.decode(MaelstromMessage.self, from: data)
            
            switch req.body {
            case .initMessage(let body):
                try await node.handleInit(req: req, body: body)
                break
            default:
                stderr.write("no message handler for type: \(req.body.type)\n")
                break
            }
        }
    }
}
