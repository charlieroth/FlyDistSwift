//
//  Node.swift
//
//
//  Created by Charles Roth on 2024-06-23.
//

import Foundation
import AsyncAlgorithms

actor Node {
    var stderr: StandardError
    var stdout: StandardOut
    
    var id: String? = nil
    var nodeIds: [String] = []
    var nextMsgId: Int = 0
    
    init() {
        self.stderr = StandardError()
        self.stdout = StandardOut()
    }
    
    func handleInit(req: MaelstromMessage, body: InitMessage) async throws {
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
