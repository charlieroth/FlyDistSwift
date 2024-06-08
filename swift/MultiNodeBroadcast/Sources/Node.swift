//
//  Node.swift
//
//
//  Created by Charles Roth on 2024-06-08.
//

import Foundation

actor Node {
    var stderr: StandardError
    var stdout: StandardOut
    
    var id: String? = nil
    var nodeIds: [String]? = nil
    var topology: [String:[String]] = [:]
    var messages: Set<Int> = Set()
    var nextMsgId: Int
    var broadcastTask: Task<Void, Error>?
    
    init() {
        self.stderr = StandardError()
        self.stdout = StandardOut()
        self.nextMsgId = 0
        self.broadcastTask = nil
    }
    
    func broadcast(every duration: Duration) {
        self.broadcastTask = Task {
            while true {
                try await Task.sleep(for: duration)
                if self.id == nil || self.topology.isEmpty {
                    continue
                }
                
                guard let nodesToBroadcastTo = self.topology[self.id!] else {
                    self.stderr.write("no topology for node id \(self.id!)")
                    continue
                }
                
                let messages = Array(self.messages)
                // broadcast messages to the topology
                for nodeId in nodesToBroadcastTo {
                    if nodeId == self.id! { continue }
                    try self.send(message:
                        MaelstromMessage(
                            src: self.id!,
                            dest: nodeId,
                            body: .gossipMessage(
                                GossipMessage(
                                    type: "gossip",
                                    messages: messages
                                )
                            )
                        )
                    )
                }
            }
        }
    }
    
    func handleInit(message: MaelstromMessage, body: InitMessage) throws {
        // update
        self.id = body.node_id
        self.nodeIds = body.node_ids
        // reply
        let reply = MaelstromMessage(
            src: self.id!,
            dest: message.src,
            body: .initOkMessage(
                InitOkMessage(
                    type: "init_ok",
                    in_reply_to: body.msg_id,
                    msg_id: self.nextMsgId
                )
            )
        )
        try self.reply(message: reply)
    }
    
    func handleTopology(message: MaelstromMessage, body: TopologyMessage) throws {
        // update
        self.topology = body.topology
        // reply
        let reply = MaelstromMessage(
            src: self.id!,
            dest: message.src,
            body: .topologyOkMessage(
                TopologyOkMessage(
                    type: "topology_ok",
                    msg_id: self.nextMsgId,
                    in_reply_to: body.msg_id
                )
            )
        )
        try self.reply(message: reply)
    }
    
    func handleBroadcast(message: MaelstromMessage, body: BroadcastMessage) throws {
        self.messages.insert(body.message)
        
        guard let nodesToBroadcastTo = self.topology[self.id!] else {
            self.stderr.write("no topology for node id \(self.id!)")
            return
        }
        
        Task {
            // broadcast messages to the topology
            for nodeId in nodesToBroadcastTo {
                if nodeId == self.id! { continue }
                try self.send(message:
                    MaelstromMessage(
                        src: self.id!,
                        dest: nodeId,
                        body: .gossipMessage(
                            GossipMessage(
                                type: "gossip",
                                messages: Array(self.messages)
                            )
                        )
                    )
                )
            }
        }
        
        // reply
        let reply = MaelstromMessage(
            src: self.id!,
            dest: message.src,
            body: .broadcastOkMessage(
                BroadcastOkMessage(
                    type: "broadcast_ok",
                    msg_id: self.nextMsgId,
                    in_reply_to: body.msg_id
                )
            )
        )
        try self.reply(message: reply)
    }
    
    func handleRead(message: MaelstromMessage, body: ReadMessage) throws {
        let reply = MaelstromMessage(
            src: self.id!,
            dest: message.src,
            body: .readOkMessage(
                ReadOkMessage(
                    type: "read_ok",
                    msg_id: self.nextMsgId,
                    in_reply_to: body.msg_id,
                    messages: Array(self.messages)
                )
            )
        )
        try self.reply(message: reply)
    }
    
    func handleGossip(message: MaelstromMessage, body: GossipMessage) throws {
        for message in body.messages {
            self.messages.insert(message)
        }
    }
    
    private func reply(message: MaelstromMessage) throws {
        self.nextMsgId += 1
        try self.send(message: message)
    }
    
    private func send(message: MaelstromMessage) throws {
        let messageData = try JSONEncoder().encode(message)
        guard let messageString = String(data: messageData, encoding: .utf8) else {
            self.stderr.write("failed to stringify reply message\n")
            return
        }
        self.stdout.write(messageString)
        self.stdout.write("\n")
    }
}
