//
//  EfficientBroadcast.swift
//
//
//  Created by Charles Roth on 2024-06-08.
//

import Foundation

// ~~~~ Goals ~~~~
// 1. Messages/Op <= 30
// 2. Median Latency (50%) <= 400ms
// 3. Maxium Latency (100%) <= 600ms
//
// ~~~~ Results ~~~~
//
// Topology = star, Gossip = 50ms
// Messages/Op = ~14.7
// Median Latency = 195ms
// Maxium Latency = 281ms


@main
struct EfficientBroadcast {
    static func main() async throws {
        let stderr = StandardError()
        let node = Node()
        
        Task {
            do {
                try await node.gossip()
            } catch {
                print("gossip error: \(error)")
            }
        }
        
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
            case .topologyMessage(let body):
                Task {
                    try await node.handleTopology(req: req, body: body)
                }
                break
            case .broadcastMessage(let body):
                Task {
                    try await node.handleBroadcast(req: req, body: body)
                }
                break
            case .readMessage(let body):
                Task {
                    try await node.handleRead(req: req, body: body)
                }
                break
            case .gossipMessage(let body):
                Task {
                    try await node.handleGossip(req: req, body: body)
                }
                break
            default:
                stderr.write("no message handler for type: \(req.body.type)\n")
            }
        }
    }
}
