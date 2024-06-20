//
//  Node.swift
//
//
//  Created by Charles Roth on 2024-06-20.
//

import Foundation

struct LogEntry: Codable {
    var offset: Int
    var msg: Int
}

actor Log {
    // key -> [LogEntry(offset: msg:)]
    var log: [String:[LogEntry]] = [:]
    // key -> committed_offset
    var commits: [String:Int] = [:]
    var offsets: [String:Int] = [:]
    
    func append(key: String, logEntry: LogEntry) -> Void {
        if self.log[key] == nil {
            self.log[key] = [logEntry]
            return
        }
        
        self.log[key]?.append(logEntry)
    }
    
    func logs(startingFrom keysAndOffsets: [String:Int]) -> [String:[[Int]]] {
        var offsets: [String:[[Int]]] = [:]
        for (key, offset) in keysAndOffsets {
            if self.log[key] == nil {
                continue
            }
            
            offsets[key] = []
            for logEntry in self.log[key]! {
                if logEntry.offset >= offset {
                    offsets[key]!.append([logEntry.offset, logEntry.msg])
                }
            }
        }
        return offsets
    }
    
    func commitOffsets(for keysAndOffsets: [String:Int]) -> Void {
        for (key, offset) in keysAndOffsets {
            self.commits[key] = offset
        }
    }
    
    func getCommitOffsets(for keys: [String]) -> [String:Int] {
        return self.commits
    }
    
    func incOffset(for key: String) -> Int {
        if self.offsets[key] == nil {
            self.offsets[key] = 1
            return 1
        }
        
        self.offsets[key]! += 1
        return self.offsets[key]!
    }
}

actor Node {
    var stderr: StandardError
    var stdout: StandardOut
    
    var id: String? = nil
    var nodeIds: [String] = []
    var log: Log
    
    init() {
        self.stderr = StandardError()
        self.stdout = StandardOut()
        self.log = Log()
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
    
    func handleSend(req: MaelstromMessage, body: SendMessage) async throws {
        let offset = await self.log.incOffset(for: body.key)
        let logEntry: LogEntry = LogEntry(offset: offset, msg: body.msg)
        await self.log.append(key: body.key, logEntry: logEntry)
        
        try self.reply(
            req: req,
            body: .sendOkMessage(
                SendOkMessage(
                    type: "send_ok",
                    offset: offset,
                    in_reply_to: body.msg_id
                )
            )
        )
    }

    func handlePoll(req: MaelstromMessage, body: PollMessage) async throws {
        let msgs = await self.log.logs(startingFrom: body.offsets)
        try self.reply(
            req: req,
            body: .pollOkMessage(
                PollOkMessage(
                    type: "poll_ok",
                    msgs: msgs,
                    in_reply_to: body.msg_id
                )
            )
        )
    }
    
    func handleCommitOffsets(req: MaelstromMessage, body: CommitOffsetsMessage) async throws {
        await self.log.commitOffsets(for: body.offsets)
        try self.reply(
            req: req,
            body: .commitOffsetsOkMessage(
                CommitOffsetsOkMessage(
                    type: "commit_offsets_ok",
                    in_reply_to: body.msg_id
                )
            )
        )
    }

    func handleListCommittedOffsets(req: MaelstromMessage, body: ListCommittedOffsetsMessage) async throws {
        let committedOffsets = await self.log.getCommitOffsets(for: body.keys)
        try self.reply(
            req: req,
            body: .listCommittedOffsetsOkMessage(
                ListCommittedOffsetsOkMessage(
                    type: "list_committed_offsets_ok",
                    offsets: committedOffsets,
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
