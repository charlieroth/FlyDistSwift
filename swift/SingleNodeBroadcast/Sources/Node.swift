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
    var messages: [Int] = []
    var nextMsgId: Int
    
    init() {
        self.stderr = StandardError()
        self.stdout = StandardOut()
        self.nextMsgId = 0
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
        self.messages.append(body.message)
        
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
                        body: .broadcastMessage(
                            BroadcastMessage(
                                type: "broadcast",
                                msg_id: body.msg_id,
                                message: body.message
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
        let messages = self.messages
        
        let reply = MaelstromMessage(
            src: self.id!,
            dest: message.src,
            body: .readOkMessage(
                ReadOkMessage(
                    type: "read_ok",
                    msg_id: self.nextMsgId,
                    in_reply_to: body.msg_id,
                    messages: messages
                )
            )
        )
        try self.reply(message: reply)
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
