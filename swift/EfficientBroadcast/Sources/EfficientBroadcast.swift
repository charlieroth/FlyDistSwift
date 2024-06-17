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
// Topology = tree4, Gossip = 500ms
// - Messages/Op = ~1.6
// - Median Latency = 1979ms
// - Maximum Latency = 2533ms
//
// Topology = tree4, Gossip = 100ms
// - Messages/Op = ~8.1
// - Median Latency = 612ms
// - Maximum Latency = 944ms
//
// Topology = tree4, Gossip = 50ms
// - Messages/Op = ~15.4
// - Median Latency = 430ms
// - Maximum Latency = 659ms
//
// Topology = tree4, Gossip = 25ms
// - Messages/Op = ~27.9
// - Median Latency = 417ms
// - Maximum Latency = 586ms

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
//            stderr.write("received: \(req.body.type)\n")
    
            switch req.body {
            case .initMessage(let body):
                try await node.handleInit(req: req, body: body)
                break
            case .topologyMessage(let body):
                try await node.handleTopology(req: req, body: body)
                break
            case .broadcastMessage(let body):
                try await node.handleBroadcast(req: req, body: body)
                break
            case .readMessage(let body):
                try await node.handleRead(req: req, body: body)
                break
            case .gossipMessage(let body):
                try await node.handleGossip(req: req, body: body)
                break
            default:
                stderr.write("no message handler for type: \(req.body.type)\n")
            }
        }
    }
}
