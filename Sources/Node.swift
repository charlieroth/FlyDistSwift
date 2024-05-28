//
//  Node.swift
//
//
//  Created by Charlie Roth on 2024-05-28.
//

import Foundation

actor Node {
    var id: String? = nil
    var nodes: [String]? = nil
    var messages: [BroadcastBody] = []
    var topology: [String:[String]]? = nil
    
    func handleInit(message: Message, body: InitBody) -> Reply<InitReply> {
        self.id = body.node_id
        self.nodes = body.node_ids
        
        return Reply<InitReply>(
            src: body.node_id,
            dest: message.src,
            body: InitReply(in_reply_to: body.msg_id)
        )
    }
    
    func handleEcho(message: Message, body: EchoBody) -> Reply<EchoReply> {
        return Reply<EchoReply>(
            src: self.id!,
            dest: message.src,
            body: EchoReply(
                in_reply_to: body.msg_id,
                echo: body.echo
            )
        )
    }
    
    func handleGenerate(message: Message, body: GenerateBody) -> Reply<GenerateReply> {
        return Reply<GenerateReply>(
            src: self.id!,
            dest: message.src,
            body: GenerateReply(in_reply_to: body.msg_id)
        )
    }
    
    func handleTopology(message: Message, body: TopologyBody) -> Reply<TopologyReply> {
        self.topology = body.topology
        
        return Reply<TopologyReply>(
            src: self.id!,
            dest: message.src,
            body: TopologyReply(in_reply_to: body.msg_id)
        )
    }
    
    func handleBroadcast(message: Message, body: BroadcastBody) -> Reply<BroadcastReply> {
        messages.append(body)
        
        return Reply<BroadcastReply>(
            src: self.id!,
            dest: message.src,
            body: BroadcastReply(in_reply_to: body.msg_id)
        )
    }
    
    func handleRead(message: Message, body: ReadBody) -> Reply<ReadReply> {
        return Reply<ReadReply>(
            src: self.id!,
            dest: message.src,
            body: ReadReply(
                in_reply_to: body.msg_id,
                messages: self.messages.map({ body in
                    body.message
                })
            )
        )
    }
}
