//
//  Node.swift
//
//
//  Created by Charles Roth on 2024-06-25.
//

import Foundation
import AsyncAlgorithms

enum StoreError: Error {
    case keyDoesNotExist
}

actor Store {
    var data: [Int:Int?] = [:]
    
    func process(txnOperations: [TxnOperation]) -> [TxnOperation] {
        var txnOperationResults: [TxnOperation] = []
        
        for txn in txnOperations {
            if txn.op == "r" {
                if let value  = self.get(key: txn.key) {
                    txnOperationResults.append(
                        TxnOperation(
                            op: "r",
                            key: txn.key,
                            value: value
                        )
                    )
                } else {
                    txnOperationResults.append(
                        TxnOperation(
                            op: "r",
                            key: txn.key,
                            value: nil
                        )
                    )
                }
            } else if txn.op == "w" {
                self.put(key: txn.key, value: txn.value)
                txnOperationResults.append(
                    TxnOperation(
                        op: txn.op,
                        key: txn.key,
                        value: txn.value
                    )
                )
            } else {
                fatalError("unknown transaction type: \(txn)")
            }
        }
        
        return txnOperationResults
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
        let txnOperationsResults = await self.store.process(txnOperations: body.txn)
        try self.reply(
            req: req,
            body: .txnOkMessage(
                TxnOkMessage(
                    type: "txn_ok",
                    in_reply_to: body.msg_id,
                    txn: txnOperationsResults
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
