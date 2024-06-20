//
//  MultiNodeKafka.swift
//
//
//  Created by Charles Roth on 2024-06-20.
//

import Foundation

@main
struct MultiNodeKafka {
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
            case .sendMessage(let body):
                try await node.handleSend(req: req, body: body)
                break
            case .pollMessage(let body):
                try await node.handlePoll(req: req, body: body)
                break
            case .commitOffsetsMessage(let body):
                try await node.handleCommitOffsets(req: req, body: body)
                break
            case .listCommittedOffsetsMessage(let body):
                try await node.handleListCommittedOffsets(req: req, body: body)
                break
            default:
                stderr.write("no message handler for type: \(req.body.type)\n")
                break
            }
        }
    }
}
