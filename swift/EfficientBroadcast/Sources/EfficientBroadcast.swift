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
            try await node.gossip(every: .milliseconds(40))
        }
        
        while let line = readLine(strippingNewline: true) {
            let data = line.data(using: .utf8)!
            let decoder = JSONDecoder()
            let message = try decoder.decode(MaelstromMessage.self, from: data)
            stderr.write("received: \(message)\n")
            
            switch message.body {
            case .initMessage(let initMessage):
                try await node.handleInit(message: message, body: initMessage)
            case .topologyMessage(let topologyMessage):
                try await node.handleTopology(message: message, body: topologyMessage)
            case .broadcastMessage(let broadcastMessage):
                try await node.handleBroadcast(message: message, body: broadcastMessage)
            case .readMessage(let readMessage):
                try await node.handleRead(message: message, body: readMessage)
            case .gossipMessage(let gossipMessage):
                try await node.handleGossip(message: message, body: gossipMessage)
            case .gossipOkMessage(let gossipOkMessage):
                await node.handleGossipOk(message: message, body: gossipOkMessage)
            default:
                stderr.write("no message handler for type: \(message.body.type)\n")
            }
        }
    }
}
