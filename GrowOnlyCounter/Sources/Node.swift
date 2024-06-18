//
//  Node.swift
//
//
//  Created by Charles Roth on 2024-06-18.
//

import Foundation

struct Counter: Codable {
    var version: Int = 0
    var value: Int = 0
}

// https://martinfowler.com/articles/patterns-of-distributed-systems/version-vector.html
// https://en.wikipedia.org/wiki/Version_vector
// https://github.com/elh/gossip-glomers/blob/main/src/4_grow_only_counter.clj
actor KV {
    var counters: [String:Counter]
    
    init() {
        self.counters = [:]
    }
    
    init(nodeIds: [String]) {
        self.counters = [:]
        
        for nodeId in nodeIds {
            self.counters[nodeId] = Counter()
        }
    }
    
    func add(nodeId: String, delta: Int) -> Void {
        let nodeCounter = self.counters[nodeId]!
        self.counters[nodeId] = Counter(
            version: nodeCounter.version + 1,
            value: nodeCounter.value + delta
        )
    }
    
    func read() -> Int {
        return self.counters.values.reduce(0, { acc, curr in
            acc + curr.value
        })
    }
    
    func merge(with incoming: [String:Counter]) -> Void {
        for (nodeId, incomingCounter) in incoming {
            let currentCounter = self.counters[nodeId]!
            if incomingCounter.version > currentCounter.version {
                self.counters[nodeId] = incomingCounter
            }
        }
    }
}

actor Node {
    var stderr: StandardError
    var stdout: StandardOut
    
    var id: String? = nil
    var nodeIds: [String] = []
    var kv: KV = KV()
    
    init() {
        self.stderr = StandardError()
        self.stdout = StandardOut()
    }
    
    func gossip(every sleepFor: Duration) async throws {
        while true {
            let counters = await self.kv.counters
            if counters.isEmpty {
                try await Task.sleep(for: sleepFor)
                continue
            }
            
            for nodeId in self.nodeIds {
                if nodeId == self.id! { continue }
                
                try self.send(
                    dest: nodeId,
                    body: .gossipMessage(
                        GossipMessage(
                            type: "gossip",
                            counters: counters
                        )
                    )
                )
            }
            try await Task.sleep(for: sleepFor)
        }
    }
    
    func handleInit(req: MaelstromMessage, body: InitMessage) async throws {
        self.id = body.node_id
        self.nodeIds = body.node_ids
        self.kv = KV(nodeIds: body.node_ids)

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
    
    func handleRead(req: MaelstromMessage, body: ReadMessage) async throws {
        let value = await self.kv.read()
        try self.reply(
            req: req,
            body: .readOkMessage(
                ReadOkMessage(
                    type: "read_ok",
                    value: value,
                    in_reply_to: body.msg_id
                )
            )
        )
    }
    
    func handleAdd(req: MaelstromMessage, body: AddMessage) async throws {
        await self.kv.add(nodeId: self.id!, delta: body.delta)
        try self.reply(
            req: req,
            body: .addOkMessage(
                AddOkMessage(
                    type: "add_ok",
                    in_reply_to: body.msg_id
                )
            )
        )
    }
    
    func handleGossip(req: MaelstromMessage, body: GossipMessage) async throws {
        await self.kv.merge(with: body.counters)
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
