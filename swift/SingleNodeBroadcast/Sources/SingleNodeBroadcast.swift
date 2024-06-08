//
//  SingleNodeBroadcast.swift
//
//
//  Created by Charles Roth on 2024-06-08.
//

import Foundation

@main
struct SingleNodeBroadcast {
    static func main() async throws {
        let stderr = StandardError()
        let node = Node()
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
            default:
                stderr.write("no message handler for type: \(message.body.type)\n")
            }
        }
    }
}
