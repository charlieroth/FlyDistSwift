//
//  Node.swift
//
//
//  Created by Charles Roth on 2024-06-08.
//

import Foundation
import AsyncAlgorithms

enum NodeError: Error {
    case emptyTopology
    case rpcError
    case rpcInvalidMessage
    case rpcNoResponse
}

let maxRetry = 100
let retrySleepDuration = Duration.seconds(1)

actor Node {
    var stderr: StandardError
    var stdout: StandardOut
    
    var id: String? = nil
    var nodeIds: [String] = []
    var neighbors: [String] = []
    var messages: Set<Int>
    var nextMsgId: Int
    
    init() {
        self.stderr = StandardError()
        self.stdout = StandardOut()
        self.nextMsgId = 0
        self.messages = Set()
    }
    
    func gossip() async throws {
        while true {
            try await Task.sleep(for: .milliseconds(50))
            if self.neighbors.isEmpty || self.messages.isEmpty {
                continue
            }
            
            let messages = self.messages
            for neighbor in self.neighbors {
                try self.send(
                    dest: neighbor,
                    body: .gossipMessage(
                        GossipMessage(type: "gossip", messages: messages)
                    )
                )
            }
        }
    }
    
    func handleInit(req: MaelstromMessage, body: InitMessage) throws {
        self.id = body.node_id
        self.nodeIds = body.node_ids
        try self.reply(
            req: req,
            body: .initOkMessage(
                InitOkMessage(
                    type: "init_ok",
                    in_reply_to: body.msg_id
                )
            )
        )
    }
    
    func handleTopology(req: MaelstromMessage, body: TopologyMessage) throws {
        // Create star topology
        if self.id == "n0" {
            self.neighbors = Array(1...24).map({ n in "n\(n)" })
        } else {
            self.neighbors = ["n0"]
        }
        
        try self.reply(
            req: req,
            body: .topologyOkMessage(
                TopologyOkMessage(
                    type: "topology_ok",
                    in_reply_to: body.msg_id
                )
            )
        )
    }
    
    func handleGossip(req: MaelstromMessage, body: GossipMessage) async throws {
        self.messages.formUnion(body.messages)
    }
    
    func handleBroadcast(req: MaelstromMessage, body: BroadcastMessage) async throws {
        self.messages.insert(body.message)
        try self.reply(
            req: req,
            body: .broadcastOkMessage(
                BroadcastOkMessage(
                    type: "broadcast_ok",
                    in_reply_to: body.msg_id!
                )
            )
        )
    }
    
    func handleRead(req: MaelstromMessage, body: ReadMessage) throws {
        try self.reply(
            req: req,
            body: .readOkMessage(
                ReadOkMessage(
                    type: "read_ok",
                    in_reply_to: body.msg_id,
                    messages: self.messages
                )
            )
        )
    }
    
    private func reply(req: MaelstromMessage, body: MessageType) throws {
        try self.send(dest: req.src, body: body)
    }
    
    private func send(dest: String, body: MessageType) throws {
        let message = MaelstromMessage(src: self.id!, dest: dest, body: body)
        let messageData = try JSONEncoder().encode(message)
        guard let messageString = String(data: messageData, encoding: .utf8) else {
            return
        }
        self.stdout.write("\(messageString)\n")
    }
}
