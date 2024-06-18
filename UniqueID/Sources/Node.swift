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
        try self.send(reply: reply)
    }
    
    func handleGenerate(message: MaelstromMessage, body: GenerateMessage) throws {
        // reply
        let reply = MaelstromMessage(
            src: self.id!,
            dest: message.src,
            body: .generateOkMessage(
                GenerateOkMessage(
                    type: "generate_ok",
                    in_reply_to: body.msg_id,
                    msg_id: self.nextMsgId,
                    id: UUID()
                )
            )
        )
        try self.send(reply: reply)
    }
    
    private func send(reply: MaelstromMessage) throws {
        self.nextMsgId += 1
        let replyData = try JSONEncoder().encode(reply)
        guard let replyString = String(data: replyData, encoding: .utf8) else {
            self.stderr.write("failed to stringify reply message\n")
            return
        }
        
        self.stdout.write(replyString)
        self.stdout.write("\n")
    }
}
