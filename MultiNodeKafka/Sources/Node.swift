//
//  Node.swift
//
//
//  Created by Charles Roth on 2024-06-20.
//

import Foundation
import AsyncAlgorithms

enum NodeError: Error {
    case rpcFailure
    case failedToAssignKey
    case invalidNodeId
}

actor RpcNode {
    var closed: Bool = false
    var ch: AsyncChannel<RpcOkMessage>
    
    init(ch: AsyncChannel<RpcOkMessage>) {
        self.ch = ch
    }
    
    func dispatch(msg: RpcOkMessage) async -> Void {
        await self.ch.send(msg)
        self.ch.finish()
        self.closed = true
    }
}

struct LogEntry: Codable {
    var offset: Int
    var msg: Int
}

actor Log {
    var log: [String:[LogEntry]] = [:]
    var commits: [String:Int] = [:]
    var offsets: [String:Int] = [:]
    
    func append(key: String, logEntry: LogEntry) -> Void {
        if self.log[key] == nil {
            self.log[key] = [logEntry]
            return
        }
        
        self.log[key]?.append(logEntry)
    }
    
    func msgs(for keysAndOffsets: [String:Int]) -> [String:[[Int]]] {
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
    
    var log: Log
    
    var id: String? = nil
    var nodeIds: [String] = []
    var callbacks: [Int:RpcNode] = [:]
    var nextMsgId: Int = 0
    
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
        let rpcDest = try keyToNode(key: body.key)
        self.stderr.write("handleSend: [\(body.key),\(body.msg)]->\(rpcDest)\n")
        
        if rpcDest != self.id! {
            let rpcOkMessage = try await self.syncRpc(
                dest: rpcDest,
                body: .sendRpcMessage(
                    SendRpcMessage(
                        type: "send_rpc",
                        key: body.key,
                        msg: body.msg,
                        msg_id: body.msg_id
                    )
                )
            )
            
            if case .sendRpcOkMessage(let response) = rpcOkMessage {
                self.callbacks.removeValue(forKey: response.in_reply_to)
                return try self.reply(
                    req: req,
                    body: .sendOkMessage(
                        SendOkMessage(
                            type: "send_ok",
                            offset: response.offset,
                            in_reply_to: body.msg_id
                        )
                    )
                )
            }
            
            return self.stderr.write(
                "ERROR: received unexpected response for send_rpc \(rpcOkMessage)\n"
            )
        }
        
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
    
    func handleSendRpc(req: MaelstromMessage, body: SendRpcMessage) async throws {
        let offset = await self.log.incOffset(for: body.key)
        let logEntry: LogEntry = LogEntry(offset: offset, msg: body.msg)
        await self.log.append(key: body.key, logEntry: logEntry)
        
        try self.reply(
            req: req,
            body: .sendRpcOkMessage(
                SendRpcOkMessage(
                    type: "send_rpc_ok",
                    offset: offset,
                    in_reply_to: body.msg_id
                )
            )
        )
    }
    
    func handleSendRpcOk(req: MaelstromMessage, body: SendRpcOkMessage) async throws {
        if let rpcNode = self.callbacks[body.in_reply_to] {
            await rpcNode.dispatch(msg: .sendRpcOkMessage(body))
            return
        }
        
        self.stderr.write("No send_rpc_ok callback registered for \(body.in_reply_to)\n")
    }

    func handlePoll(req: MaelstromMessage, body: PollMessage) async throws {
        let (localOffsets, remoteOffsets) = try self.offsetsForLocalAndRemote(
            offsets: body.offsets
        )
        
        if !localOffsets.isEmpty && remoteOffsets.isEmpty {
            let msgs = await self.log.msgs(for: localOffsets)
            
            return try self.reply(
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
        
        if localOffsets.isEmpty && !remoteOffsets.isEmpty {
            let rpcDest = try self.getOtherNode()
            let rpcOkMessage = try await self.syncRpc(
                dest: rpcDest,
                body: .pollRpcMessage(
                    PollRpcMessage(
                        type: "poll_rpc",
                        offsets: remoteOffsets,
                        msg_id: body.msg_id
                    )
                )
            )
            
            if case .pollRpcOkMessage(let response) = rpcOkMessage {
                self.callbacks.removeValue(forKey: response.in_reply_to)
                
                return try self.reply(
                    req: req,
                    body: .pollOkMessage(
                        PollOkMessage(
                            type: "poll_ok",
                            msgs: response.msgs,
                            in_reply_to: body.msg_id
                        )
                    )
                )
            }
            
            return
        }
        
        if !localOffsets.isEmpty && !remoteOffsets.isEmpty {
            let rpcDest = try self.getOtherNode()
            let rpcOkMessage = try await self.syncRpc(
                dest: rpcDest,
                body: .pollRpcMessage(
                    PollRpcMessage(
                        type: "poll_rpc",
                        offsets: remoteOffsets,
                        msg_id: body.msg_id
                    )
                )
            )
            
            if case .pollRpcOkMessage(let response) = rpcOkMessage {
                self.callbacks.removeValue(forKey: response.in_reply_to)
                var msgs = await self.log.msgs(for: localOffsets)
                for (k, v) in response.msgs { msgs[k] = v }
    
                return try self.reply(
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
            
            return
        }
        
        if localOffsets.isEmpty && remoteOffsets.isEmpty {
            self.stderr.write("ERROR: empty offsets received \(body.offsets)\n")
            return try self.reply(
                req: req,
                body: .pollOkMessage(
                    PollOkMessage(
                        type: "poll_ok",
                        msgs: [:],
                        in_reply_to: body.msg_id
                    )
                )
            )
        }
    }
    
    func handlePollRpc(req: MaelstromMessage, body: PollRpcMessage) async throws {
        let msgs = await self.log.msgs(for: body.offsets)
        try self.reply(
            req: req,
            body: .pollRpcOkMessage(
                PollRpcOkMessage(
                    type: "poll_rpc_ok",
                    msgs: msgs,
                    in_reply_to: body.msg_id
                )
            )
        )
    }
    
    func handlePollRpcOk(req: MaelstromMessage, body: PollRpcOkMessage) async throws {
        if let rpcNode = self.callbacks[body.in_reply_to] {
            await rpcNode.dispatch(msg: .pollRpcOkMessage(body))
            return
        }
    }
    
    func handleCommitOffsets(req: MaelstromMessage, body: CommitOffsetsMessage) async throws {
        let (localOffsets, remoteOffsets) = try self.offsetsForLocalAndRemote(
            offsets: body.offsets
        )
        
        if !localOffsets.isEmpty && remoteOffsets.isEmpty {
            await self.log.commitOffsets(for: localOffsets)
            return try self.reply(
                req: req,
                body: .commitOffsetsOkMessage(
                    CommitOffsetsOkMessage(
                        type: "commit_offsets_ok",
                        in_reply_to: body.msg_id
                    )
                )
            )
        }
        
        if localOffsets.isEmpty && !remoteOffsets.isEmpty {
            let rpcDest = try self.getOtherNode()
            let rpcOkMessage = try await self.syncRpc(
                dest: rpcDest,
                body: .commitOffsetsRpcMessageMessage(
                    CommitOffsetsRpcMessage(
                        type: "commit_offsets_rpc",
                        offsets: remoteOffsets,
                        msg_id: body.msg_id
                    )
                )
            )
            
            if case .commitOffsetsRpcMessageOkMessage(let response) = rpcOkMessage {
                self.callbacks.removeValue(forKey: response.in_reply_to)
                
                return try self.reply(
                    req: req,
                    body: .commitOffsetsOkMessage(
                        CommitOffsetsOkMessage(
                            type: "commit_offsets_ok",
                            in_reply_to: body.msg_id
                        )
                    )
                )
            }
            
            return
        }
        
        if !localOffsets.isEmpty && !remoteOffsets.isEmpty {
            let rpcDest = try self.getOtherNode()
            let rpcOkMessage = try await self.syncRpc(
                dest: rpcDest,
                body: .commitOffsetsRpcMessageMessage(
                    CommitOffsetsRpcMessage(
                        type: "commit_offsets_rpc",
                        offsets: remoteOffsets,
                        msg_id: body.msg_id
                    )
                )
            )
            
            if case .commitOffsetsRpcMessageOkMessage(let response) = rpcOkMessage {
                self.callbacks.removeValue(forKey: response.in_reply_to)
                await self.log.commitOffsets(for: localOffsets)
                
                return try self.reply(
                    req: req,
                    body: .commitOffsetsOkMessage(
                        CommitOffsetsOkMessage(
                            type: "commit_offsets_ok",
                            in_reply_to: body.msg_id
                        )
                    )
                )
            }
            
            return
        }
        
        if localOffsets.isEmpty && remoteOffsets.isEmpty {
            return try self.reply(
                req: req,
                body: .commitOffsetsOkMessage(
                    CommitOffsetsOkMessage(
                        type: "commit_offsets_ok",
                        in_reply_to: body.msg_id
                    )
                )
            )
        }
    }
    
    func handleCommitOffsetsRpc(req: MaelstromMessage, body: CommitOffsetsRpcMessage) async throws {
        await self.log.commitOffsets(for: body.offsets)
        try self.reply(
            req: req,
            body: .commitOffsetsRpcOkMessage(
                CommitOffsetsRpcOkMessage(
                    type: "commit_offsets_rpc_ok",
                    in_reply_to: body.msg_id
                )
            )
        )
    }
    
    func handleCommitOffsetsRpcOk(req: MaelstromMessage, body: CommitOffsetsRpcOkMessage) async throws {
        if let rpcNode = self.callbacks[body.in_reply_to] {
            await rpcNode.dispatch(msg: .commitOffsetsRpcMessageOkMessage(body))
            return
        }
    }

    func handleListCommittedOffsets(req: MaelstromMessage, body: ListCommittedOffsetsMessage) async throws {
        let (localKeys, remoteKeys) = try self.keysForLocalAndRemote(keys: body.keys)
        
        if !localKeys.isEmpty && remoteKeys.isEmpty {
            let offsets = await self.log.getCommitOffsets(for: localKeys)
            return try self.reply(
                req: req,
                body: .listCommittedOffsetsOkMessage(
                    ListCommittedOffsetsOkMessage(
                        type: "list_committed_offsets_ok",
                        offsets: offsets,
                        in_reply_to: body.msg_id
                    )
                )
            )
        }
        
        if localKeys.isEmpty && !remoteKeys.isEmpty {
            let rpcDest = try self.getOtherNode()
            let rpcOkMessage = try await self.syncRpc(
                dest: rpcDest,
                body: .listCommittedOffsetsRpcMessage(
                    ListCommittedOffsetsRpcMessage(
                        type: "list_committed_offsets_rpc",
                        keys: remoteKeys,
                        msg_id: body.msg_id
                    )
                )
            )
            
            if case .listCommittedOffsetsRpcOkMessage(let response) = rpcOkMessage {
                self.callbacks.removeValue(forKey: response.in_reply_to)
                return try self.reply(
                    req: req,
                    body: .listCommittedOffsetsOkMessage(
                        ListCommittedOffsetsOkMessage(
                            type: "list_committed_offsets_ok",
                            offsets: response.offsets,
                            in_reply_to: body.msg_id
                        )
                    )
                )
            }
            
            return
        }
        
        if !localKeys.isEmpty && !remoteKeys.isEmpty {
            let rpcDest = try self.getOtherNode()
            let rpcOkMessage = try await self.syncRpc(
                dest: rpcDest,
                body: .listCommittedOffsetsRpcMessage(
                    ListCommittedOffsetsRpcMessage(
                        type: "list_committed_offsets_rpc",
                        keys: remoteKeys,
                        msg_id: body.msg_id
                    )
                )
            )
            
            if case .listCommittedOffsetsRpcOkMessage(let response) = rpcOkMessage {
                self.callbacks.removeValue(forKey: response.in_reply_to)
                let remoteOffsets = response.offsets
                var offsets = await self.log.getCommitOffsets(for: localKeys)
                for (k, v) in remoteOffsets { offsets[k] = v }
                
                return try self.reply(
                    req: req,
                    body: .listCommittedOffsetsOkMessage(
                        ListCommittedOffsetsOkMessage(
                            type: "list_committed_offsets_ok",
                            offsets: offsets,
                            in_reply_to: body.msg_id
                        )
                    )
                )
            }
            
            return
        }
        
        if localKeys.isEmpty && remoteKeys.isEmpty {
            return try self.reply(
                req: req,
                body: .listCommittedOffsetsOkMessage(
                    ListCommittedOffsetsOkMessage(
                        type: "list_committed_offsets_ok",
                        offsets: [:],
                        in_reply_to: body.msg_id
                    )
                )
            )
        }
    }
    
    func handleListCommittedOffsetsRpc(req: MaelstromMessage, body: ListCommittedOffsetsRpcMessage) async throws {
        let offsets = await self.log.getCommitOffsets(for: body.keys)
        try self.reply(
            req: req,
            body: .listCommittedOffsetsRpcOkMessage(
                ListCommittedOffsetsRpcOkMessage(
                    type: "list_committed_offsets_rpc_ok",
                    offsets: offsets,
                    in_reply_to: body.msg_id
                )
            )
        )
    }
    
    func handleListCommittedOffsetsRpcOk(req: MaelstromMessage, body: ListCommittedOffsetsRpcOkMessage) async throws {
        if let rpcNode = self.callbacks[body.in_reply_to] {
            await rpcNode.dispatch(msg: .listCommittedOffsetsRpcOkMessage(body))
            return
        }
    }
    
    private func syncRpc(dest: String, body: RpcMessage) async throws -> RpcOkMessage {
        let ch: AsyncChannel<RpcOkMessage> = AsyncChannel()
        let rpcNode = RpcNode(ch: ch)
        try self.rpc(dest: dest, body: body, rpcNode: rpcNode)
        
        let rpcTask: Task<RpcOkMessage, Error> = Task {
            for await msg in ch {
                try Task.checkCancellation()
                return msg
            }
            
            throw NodeError.rpcFailure
        }
        
        let timeoutTask = Task {
            try await Task.sleep(for: .seconds(1))
            rpcTask.cancel()
        }
        
        let result = try await rpcTask.value
        timeoutTask.cancel()
        return result
    }
    
    private func rpc(dest: String, body: RpcMessage, rpcNode: RpcNode) throws {
        self.nextMsgId += 1
        let msgId = self.nextMsgId
        self.callbacks[msgId] = rpcNode
        
        switch body {
        case .sendRpcMessage(var body):
            body.msg_id = msgId
            try self.send(dest: dest, body: .sendRpcMessage(body))
        case .pollRpcMessage(var body):
            body.msg_id = msgId
            try self.send(dest: dest, body: .pollRpcMessage(body))
        case .commitOffsetsRpcMessageMessage(var body):
            body.msg_id = msgId
            try self.send(dest: dest, body: .commitOffsetsRpcMessage(body))
        case .listCommittedOffsetsRpcMessage(var body):
            body.msg_id = msgId
            try self.send(dest: dest, body: .listCommittedOffsetsRpcMessage(body))
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
    
    private func keysForLocalAndRemote(keys: [String]) throws -> ([String], [String]) {
        let forSelf = try keys.filter { key in
            let nodeId = try self.keyToNode(key: key)
            return nodeId == self.id!
        }
        
        let forRemote = try keys.filter { key in
            let nodeId = try self.keyToNode(key: key)
            return nodeId != self.id!
        }
        
        return (forSelf, forRemote)
    }
    
    private func offsetsForLocalAndRemote(offsets: [String:Int]) throws -> ([String:Int], [String:Int]) {
        let local = try offsets.filter { (key, _) in
            let nodeId = try self.keyToNode(key: key)
            return nodeId == self.id!
        }
        
        let remote = try offsets.filter { (key, _) in
            let nodeId = try self.keyToNode(key: key)
            return nodeId != self.id!
        }
        
        return (local, remote)
    }
    
    private func keyToNode(key: String) throws -> String {        
        if let keyInt = Int(key) {
            let nodeId = keyInt % self.nodeIds.count
            return "n\(nodeId)"
        }
        
        throw NodeError.failedToAssignKey
    }
    
    private func getOtherNode() throws -> String {
        if self.id! == "n0" { return "n1" }
        if self.id! == "n1" { return "n0" }
        throw NodeError.invalidNodeId
    }
}
