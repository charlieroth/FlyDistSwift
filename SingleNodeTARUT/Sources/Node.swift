//
//  Node.swift
//
//
//  Created by Charles Roth on 2024-06-25.
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

enum StoreError: Error {
    case keyDoesNotExist
}

actor Store {
    var data: [Int:Int?] = [:]
    
    func process(txn: [TxnOperation]) -> [TxnOperation] {
        var result: [TxnOperation] = []
        
        for operation in txn {
            if operation.op == "r" {
                if let value  = self.get(key: operation.key) {
                    result.append(
                        TxnOperation(
                            op: "r",
                            key: operation.key,
                            value: value
                        )
                    )
                } else {
                    result.append(
                        TxnOperation(
                            op: "r",
                            key: operation.key,
                            value: nil
                        )
                    )
                }
            } else if operation.op == "w" {
                self.put(key: operation.key, value: operation.value)
                result.append(
                    TxnOperation(
                        op: operation.op,
                        key: operation.key,
                        value: operation.value
                    )
                )
            } else {
                fatalError("unknown transaction type: \(txn)")
            }
        }
        
        return result
    }
    
    func put(key: Int, value: Int?) {
        self.data[key] = value
    }
    
    func get(key: Int) -> Int?? {
        return self.data[key]
    }
    
    func has(key: Int) -> Bool {
        return self.data[key] != nil
    }
}

actor Node {
    var stderr: StandardError
    var stdout: StandardOut
    
    var id: String? = nil
    var nodeIds: [String] = []
    var nextMsgId: Int = 0
    
    var callbacks: [Int:RpcNode] = [:]
    var store: Store
    
    init() {
        self.stderr = StandardError()
        self.stdout = StandardOut()
        self.store = Store()
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
    
    func handleTxn(req: MaelstromMessage, body: TxnMessage) async throws {
        // Only writes need to be replicated to other node
        let txnOnlyWrites = body.txn.filter { $0.op == "w" }
        if !txnOnlyWrites.isEmpty {
            let rpcDest = try self.remoteNode()
            let rpcOkMessage = try await self.syncRpc(
                dest: rpcDest,
                body: .txnRpcMessage(
                    TxnRpcMessage(
                        type: "txn_rpc",
                        msg_id: body.msg_id,
                        txn: txnOnlyWrites
                    )
                )
            )
            
            if case .txnRpcOkMessage(let response) = rpcOkMessage {
                self.callbacks.removeValue(forKey: response.in_reply_to)
                let localTxnResult = await self.store.process(txn: body.txn)
                try self.reply(
                    req: req,
                    body: .txnOkMessage(
                        TxnOkMessage(
                            type: "txn_ok",
                            in_reply_to: body.msg_id,
                            txn: localTxnResult
                        )
                    )
                )
            } else {
                self.stderr.write("received invalid rpc_ok message \(rpcOkMessage)\n")
            }
        } else {
            let localTxnResult = await self.store.process(txn: body.txn)
            try self.reply(
                req: req,
                body: .txnOkMessage(
                    TxnOkMessage(
                        type: "txn_ok",
                        in_reply_to: body.msg_id,
                        txn: localTxnResult
                    )
                )
            )
        }
    }
    
    func handleTxnRpc(req: MaelstromMessage, body: TxnRpcMessage) async throws {
        let localTxnResult = await self.store.process(txn: body.txn)
        try self.reply(
            req: req,
            body: .txnRpcOkMessage(
                TxnRpcOkMessage(
                    type: "txn_rpc_ok",
                    in_reply_to: body.msg_id,
                    txn: localTxnResult
                )
            )
        )
    }
    
    func handleTxnRpcOk(req: MaelstromMessage, body: TxnRpcOkMessage) async throws {
        if let rpcNode = self.callbacks[body.in_reply_to] {
            await rpcNode.dispatch(msg: .txnRpcOkMessage(body))
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
        case .txnRpcMessage(var txnRpcBody):
            txnRpcBody.msg_id = msgId
            try self.send(dest: dest, body: .txnRpcMessage(txnRpcBody))
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
    
    private func remoteNode() throws -> String {
        if self.id! == "n0" { return "n1" }
        if self.id! == "n1" { return "n0" }
        throw NodeError.invalidNodeId
    }
}
