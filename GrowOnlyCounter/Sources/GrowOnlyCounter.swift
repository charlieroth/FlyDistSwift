//
//  GrowOnlyCounter.swift
//
//
//  Created by Charles Roth on 2024-06-18.
//

import Foundation

@main
struct GrowOnlyCounter {
    static func main() async throws {
        let stderr = StandardError()
        let node = Node()
        
        Task {
            try await node.gossip(every: .milliseconds(500))
        }
        
        while let line = readLine(strippingNewline: true) {
            let data = line.data(using: .utf8)!
            let decoder = JSONDecoder()
            let req = try decoder.decode(MaelstromMessage.self, from: data)
            
            switch req.body {
            case .initMessage(let body):
                try await node.handleInit(req: req, body: body)
                break
            case .addMessage(let body):
                try await node.handleAdd(req: req, body: body)
                break
            case .readMessage(let body):
                try await node.handleRead(req: req, body: body)
                break
            case .gossipMessage(let body):
                Task {
                    try await node.handleGossip(req: req, body: body)
                }
                break
            default:
                stderr.write("no message handler for type: \(req.body.type)\n")
                break
            }
        }
    }
}
