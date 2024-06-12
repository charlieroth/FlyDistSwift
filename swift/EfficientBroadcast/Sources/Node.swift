//
//  Node.swift
//
//
//  Created by Charles Roth on 2024-06-08.
//

import Foundation

enum BroadcastError: Error {
    case emptyTopology
}

actor Node {
    var stderr: StandardError
    var stdout: StandardOut
    
    var id: String? = nil
    var nodeIds: [String]? = nil
    var topology: [String:[String]] = [:]
    var messages: Set<Int>
    var nextMsgId: Int
    
    init() {
        self.stderr = StandardError()
        self.stdout = StandardOut()
        self.nextMsgId = 0
        self.messages = Set()
    }
    
    func gossip(every duration: Duration) async throws {
        while true {
            try await Task.sleep(for: duration)
            if self.id == nil || self.topology.isEmpty {
                continue
            }
            
            guard let neighbors = self.topology[self.id!] else {
               self.stderr.write("no topology for node id \(self.id!)")
               continue
            }
            
            // gossip messages to neighbors
            let messages = self.messages
            for nodeId in neighbors {
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
    
    func handleInit(message: MaelstromMessage, body: InitMessage) throws {
        self.id = body.node_id
        self.nodeIds = body.node_ids
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
        self.stderr.write("received topology: \(body)\n")
        self.topology = body.topology
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
    
    func handleBroadcast(message: MaelstromMessage, body: BroadcastMessage) async throws {
        self.messages.insert(body.message)
        
        guard let neighbors = self.topology[self.id!] else {
           self.stderr.write("no topology for node id \(self.id!)")
            throw BroadcastError.emptyTopology
        }
        
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
    
    func handleRead(message: MaelstromMessage, body: ReadMessage) async throws {
        let reply = MaelstromMessage(
            src: self.id!,
            dest: message.src,
            body: .readOkMessage(
                ReadOkMessage(
                    type: "read_ok",
                    msg_id: self.nextMsgId,
                    in_reply_to: body.msg_id,
                    messages: self.messages
                )
            )
        )
        try self.reply(message: reply)
    }
    
    func handleGossip(message: MaelstromMessage, body: GossipMessage) async throws {
        var incomingSet = body.messages
        var currentSet = self.messages
        
        // If sets are the same, no reply required
        if currentSet == incomingSet {
            return
        }
        
        let messagesForNode = incomingSet.subtracting(currentSet)
        if !messagesForNode.isEmpty {
            self.messages.formUnion(messagesForNode)
        }
        
        let messagesForSource = currentSet.subtracting(incomingSet)
        if messagesForSource.isEmpty {
            return
        }
        
        try self.send(message:
            MaelstromMessage(
                src: self.id!,
                dest: message.src,
                body: .gossipOkMessage(
                    GossipOkMessage(
                        type: "gossip_ok",
                        messages: messagesForSource
                    )
                )
            )
        )
    }
    
    func handleGossipOk(message: MaelstromMessage, body: GossipOkMessage) {
        self.messages.formUnion(body.messages)
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
