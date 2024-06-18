//
//  Node.swift
//
//
//  Created by Charles Roth on 2024-06-08.
//

import Foundation
import AsyncAlgorithms

actor Node {
    var stderr: StandardError
    var stdout: StandardOut
    
    var id: String? = nil
    var nodeIds: [String] = []
    var topology: [String:[String]] = [:]
    var messages: Set<Int> = Set()
    var nextMsgId: Int
    
    init() {
        self.stderr = StandardError()
        self.stdout = StandardOut()
        self.nextMsgId = 0
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
        self.topology = body.topology
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
    
    func handleRead(req: MaelstromMessage, body: ReadMessage) throws {
        let messages = self.messages
        try self.reply(
            req: req,
            body: .readOkMessage(
                ReadOkMessage(
                    type: "read_ok",
                    messages: messages,
                    in_reply_to: body.msg_id
                )
            )
        )
    }
    
    func handleBroadcast(req: MaelstromMessage, body: BroadcastMessage) async throws {
        try self.reply(
            req: req,
            body: .broadcastOkMessage(
                BroadcastOkMessage(
                    type: "broadcast_ok",
                    in_reply_to: body.msg_id
                )
            )
        )
        
        if self.messages.contains(body.message) { return }
        
        self.messages.insert(body.message)
        try await broadcast(req: req, body: body)
    }
    
    private func broadcast(req: MaelstromMessage, body: BroadcastMessage) async throws {
        guard let currentNodeId = self.id else {
            fatalError("current node not initialized\n")
        }
        
        guard let topology = self.topology[currentNodeId] else {
            fatalError("broadcast requires topology, no topology for \(currentNodeId)\n")
        }
        
        for node in topology {
            try self.send(
                dest: node,
                body: .broadcastMessage(body)
            )
        }
    }
    
    private func reply(req: MaelstromMessage, body: MessageType) throws {
        try self.send(dest: req.src, body: body)
    }
    
    private func send(dest: String, body: MessageType) throws {
        let req = MaelstromMessage(
            src: self.id!,
            dest: dest,
            body: body
        )
        let reqData = try JSONEncoder().encode(req)
        guard let reqString = String(data: reqData, encoding: .utf8) else {
            self.stderr.write("failed to stringify reply message\n")
            return
        }
        self.stdout.write(reqString)
        self.stdout.write("\n")
    }
}
