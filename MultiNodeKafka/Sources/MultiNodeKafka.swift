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
                Task {
                    try await node.handleInit(req: req, body: body)
                }
                break
            case .sendMessage(let body):
                Task {
                    try await node.handleSend(req: req, body: body)
                }
                break
            case .sendRpcMessage(let body):
                Task {
                    try await node.handleSendRpc(req: req, body: body)
                }
                break
            case .sendRpcOkMessage(let body):
                Task {
                    try await node.handleSendRpcOk(req: req, body: body)
                }
                break
            case .pollMessage(let body):
                Task {
                    try await node.handlePoll(req: req, body: body)
                }
                break
            case .pollRpcMessage(let body):
                Task {
                    try await node.handlePollRpc(req: req, body: body)
                }
                break
            case .pollRpcOkMessage(let body):
                Task {
                    try await node.handlePollRpcOk(req: req, body: body)
                }
                break
            case .commitOffsetsMessage(let body):
                Task {
                    try await node.handleCommitOffsets(req: req, body: body)
                }
                break
            case .commitOffsetsRpcMessage(let body):
                Task {
                    try await node.handleCommitOffsetsRpc(req: req, body: body)
                }
                break
            case .commitOffsetsRpcOkMessage(let body):
                Task {
                    try await node.handleCommitOffsetsRpcOk(req: req, body: body)
                }
                break
            case .listCommittedOffsetsMessage(let body):
                Task {
                    try await node.handleListCommittedOffsets(req: req, body: body)
                }
                break
            case .listCommittedOffsetsRpcMessage(let body):
                Task {
                    try await node.handleListCommittedOffsetsRpc(req: req, body: body)
                }
                break
            case .listCommittedOffsetsRpcOkMessage(let body):
                Task {
                    try await node.handleListCommittedOffsetsRpcOk(req: req, body: body)
                }
                break
            default:
                stderr.write("no message handler for type: \(req.body.type)\n")
                break
            }
        }
    }
}
