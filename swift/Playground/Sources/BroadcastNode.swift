//
//  BroadcastNode.swift
//
//
//  Created by Charles Roth on 2024-06-16.
//

import Foundation
import Logging
import Distributed
import DistributedCluster
import AsyncAlgorithms

enum NodeError: Error {
    case emptyTopology
    case rpcError
    case rpcInvalidMessage
    case rpcNoResponse
}

struct BroadcastMessage: Codable {
    var src: String
    var dest: String
    var msg_id: Int
    var in_reply_to: Int?
    var message: Int
}

struct BroadcastOkMessage: Codable {
    var src: String
    var dest: String
    var msg_id: Int?
    var in_reply_to: Int
}

struct ReadMessage: Codable {
    var src: String
    var dest: String
    var msg_id: Int
    var in_reply_to: Int?
}

struct ReadOkMessage: Codable {
    var src: String
    var dest: String
    var msg_id: Int?
    var in_reply_to: Int
    
    var messages: Set<Int>
}

struct ErrorMessage: Codable {
    var src: String
    var dest: String
    var code: Int
    var msg_id: Int?
    var in_reply_to: Int?
}

enum Message {
    case broadcast(BroadcastMessage)
    case broadcastOk(BroadcastOkMessage)
    case read(ReadMessage)
    case readOk(ReadOkMessage)
    case error(ErrorMessage)
}

actor BroadcastNode {
    var id: String
    var nextMsgId: Int = 0
    var nodes: Dictionary<String, BroadcastNode> = [:]
    var messages: Set<Int> = Set()
    var tasks: [Int:AsyncChannel<Message>] = [:]
    
    init(id: String) {
        self.id = id
    }
    
    func addNeighbor(id: String, neighbor: BroadcastNode) {
        self.nodes[id] = neighbor
    }
    
    func error(message: ErrorMessage) async throws -> Void {
        print("[\(self.id)]: received error from \(message.src)")
    }
    
    func broadcast(message: BroadcastMessage) async throws -> Void {
        print("[\(self.id)]: received broadcast from \(message.src)")
        
        if self.messages.contains(message.message) == false {
            
        }
        self.messages.insert(message.message)
        
        Task {
            
        }
        
        if let respondNode = self.nodes[message.src] {
            self.send(
                dest: message.src,
                message: .broadcastOk(BroadcastOkMessage(
                    src: self.id,
                    dest: message.src,
                    in_reply_to: message.msg_id
                ))
            )
        } else {
            print("[\(self.id)]: Failed to find actor in nodes by id: \(message.src)")
        }
    }
    
    func gossip(message: BroadcastMessage) {
        for (nodeId, node) in self.nodes {
            if nodeId == self.id || nodeId == message.src {
                continue
            }
            
            Task {
                for i in 0..<10 {
                    print("[\(self.id)]: Attempting rpc call \(i) for \(message.msg_id)")
                    do {
                        let msg = try await self.syncRpc(node: node, message: message)
                        switch msg {
                        case .broadcastOk(let body):
                            print("[\(self.id)]: removing rpc task for \(body.in_reply_to)")
                            if let removed = self.tasks.removeValue(forKey: body.in_reply_to) {
                                print("[\(self.id)]: rpc task removed for \(body.in_reply_to)")
                            } else {
                                print("[\(self.id)]: No rpc task for \(body.in_reply_to)")
                            }
                            break
                        case .error(let body):
                            if let removed = self.tasks.removeValue(forKey: body.in_reply_to!) {
                                print("[\(self.id)]: rpc task removed for \(body.in_reply_to!)")
                            } else {
                                print("[\(self.id)]: No rpc task for \(body.in_reply_to!)")
                            }
                            try await Task.sleep(for: .milliseconds(500))
                            continue
                        default:
                            print("[\(self.id)]: Received invalid return message from rpc")
                            break
                        }
                    } catch {
                        print("Exiting rpc retry loop")
                        break
                    }
                }
            }
        }
    }
    
    func broadcastOk(message: BroadcastOkMessage) async throws -> Void {
        print("[\(self.id)]: received broadcast_ok from \(message.src)")
    }
    
    func read(message: ReadMessage) async throws {
        print("[\(self.id)]: received read from \(message.src)")
        self.send(
            dest: message.src,
            message: .readOk(ReadOkMessage(
                src: self.id,
                dest: message.src,
                in_reply_to: message.msg_id,
                messages: self.messages
            ))
        )
    }
    
    func readOk(message: ReadOkMessage) async throws {
        print("[\(self.id)]: received read_ok - \(message.messages)")
    }
    
    func syncRpc(node: BroadcastNode, message: BroadcastMessage) async throws -> Message {
        // ----------- rpc() ----------------
        self.nextMsgId += 1
        let msgId = self.nextMsgId
        
        var messageCopy = message
        messageCopy.msg_id = msgId
        // ----------------------------------
        
        self.send(dest: message.dest, message: .broadcast(messageCopy))
        
        let responseChannel: AsyncChannel<Message> = AsyncChannel()
        self.tasks[message.msg_id] = responseChannel
        
        for await msg in responseChannel {
            print("[\(self.id)]: received message on response channel - \(msg)")
            switch msg {
            case .broadcastOk:
                return msg
            case .error:
                return msg
            default:
                print("[\(self.id)]: error, received invalid message on response channel")
                throw NodeError.rpcInvalidMessage
            }
        }
        
        print("[\(self.id)]: No rpc response")
        throw NodeError.rpcNoResponse
    }
    
    func send(dest: String, message: Message) {
        Task {
            if let destNode = self.nodes[dest] {
                switch message {
                case .broadcast(let broadcastMessage):
                    try await destNode.broadcast(message: broadcastMessage)
                case .broadcastOk(let broadcastOkMessage):
                    try await destNode.broadcastOk(message: broadcastOkMessage)
                case .read(let readMessage):
                    try await destNode.read(message: readMessage)
                case .readOk(let readOkMessage):
                    try await destNode.readOk(message: readOkMessage)
                case .error(let errorMessage):
                    try await destNode.error(message: errorMessage)
                }
            }
        }
    }
}
