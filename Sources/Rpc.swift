//
//  Rpc.swift
//
//
//  Created by Charlie Roth on 2024-05-28.
//

import Foundation

struct InitBody: Decodable {
    var type: InitBodyType
    var msg_id: Int
    var node_id: String
    var node_ids: [String]
    
    enum InitBodyType: String {
        case `init` = "init"
    }
    
    enum CodingKeys: CodingKey {
        case type, msg_id, node_id, node_ids
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let _ = try? container.decode(InitBodyType.`init`, forKey: .type) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Init message does not contain"
                )
            )
        }
        self.type = .`init`
        self.msg_id = try container.decode(Int.self, forKey: .msg_id)
        self.node_id = try container.decode(String.self, forKey: .node_id)
        self.node_ids = try container.decode([String].self, forKey: .node_ids)
    }
}


struct InitReply: Codable {
    var type: String
    var in_reply_to: Int
    var msg_id: Int
    
    init(in_reply_to: Int) {
        self.type = "init_ok"
        self.in_reply_to = in_reply_to
        self.msg_id = Int(arc4random())
    }
}

struct EchoBody: Decodable {
    var type: String
    var msg_id: Int
    var echo: String
}

struct EchoReply: Codable {
    var type: String
    var in_reply_to: Int
    var echo: String
    var msg_id: Int
    
    init(in_reply_to: Int, echo: String) {
        self.type = "echo_ok"
        self.in_reply_to = in_reply_to
        self.echo = echo
        self.msg_id = Int(arc4random())
    }
}

struct GenerateBody: Codable {
    var type: String
    var msg_id: Int
}

struct GenerateReply: Codable {
    var type: String
    var id: Int
    var in_reply_to: Int
    var msg_id: Int
    
    init(in_reply_to: Int) {
        self.type = "generate_ok"
        self.in_reply_to = in_reply_to
        self.id = Int(arc4random())
        self.msg_id = Int(arc4random())
    }
}

/// A topology message is sent at the start of the test, after initialization,
/// and informs the node of an optional network topology to use for broadcast.
/// The topology consists of a map of node IDs to lists of neighbor node IDs.
struct TopologyBody: Codable {
    var type: String
    var msg_id: Int
    var topology: [String:[String]]
}

struct TopologyReply: Codable {
    var type: String
    var in_reply_to: Int
    var msg_id: Int
    
    init(in_reply_to: Int) {
        self.type = "topology_ok"
        self.in_reply_to = in_reply_to
        self.msg_id = Int(arc4random())
    }
}

/// NOTE(charlieroth): This is technically an "Any" but I will try to get away with
/// these types and see what happens
enum BroadcastMessage: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

/// Sends a single message into the broadcast system, and requests that it be
/// broadcast to everyone. Nodes respond with a simple acknowledgement message.
struct BroadcastBody: Decodable {
    var type: String
    var message: BroadcastMessage
    var msg_id: Int
    
    enum CodingKeys: String, CodingKey {
        case type, message, msg_id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringProperty = try? container.decode(String.self, forKey: .message) {
            self.message = .string(stringProperty)
        } else if let intProperty = try? container.decode(Int.self, forKey: .message) {
            self.message = .int(intProperty)
        } else if let boolProperty = try? container.decode(Bool.self, forKey: .message) {
            self.message = .bool(boolProperty)
        } else if let doubleProperty = try? container.decode(Double.self, forKey: .message) {
            self.message = .double(doubleProperty)
        } else {
            fatalError()
        }
        
        guard let typeProperty = try? container.decode(String.self, forKey: .type) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid data type for 'type' property"
                )
            )
        }
        self.type = typeProperty
        
        guard let msgIdProperty = try? container.decode(Int.self, forKey: .msg_id) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid data type for 'msg_id' property"
                )
            )
        }
        self.msg_id = msgIdProperty
    }
}

struct BroadcastReply: Codable {
    var type: String
    var in_reply_to: Int
    var msg_id: Int
    
    init(in_reply_to: Int) {
        self.type = "broadcast_ok"
        self.in_reply_to = in_reply_to
        self.msg_id = Int(arc4random())
    }
}

/// Requests all messages present on a node.
struct ReadBody: Codable {
    var type: String
    var msg_id: Int
}

struct ReadReply: Codable {
    var type: String
    var messages: [BroadcastMessage]
    var in_reply_to: Int
    var msg_id: Int
    
    init(in_reply_to: Int, messages: [BroadcastMessage]) {
        self.type = "read_ok"
        self.messages = messages
        self.in_reply_to = in_reply_to
        self.msg_id = Int(arc4random())
    }
}

enum MessageBody {
    case `init`(InitBody)
    case echo(EchoBody)
    case generate(GenerateBody)
    case topology(TopologyBody)
    case broadcast(BroadcastBody)
    case read(ReadBody)
}

extension MessageBody: Decodable {
    enum CodingKeys: CodingKey {
        case `init`, echo, generate, topology, broadcast, read
    }
    
    init(from decoder: Decoder) throws {
        if let body = try? InitBody(from: decoder) {
            self = .`init`(body)
        } else if let body = try? EchoBody(from: decoder) {
            self = .echo(body)
        } else if let body = try? GenerateBody(from: decoder) {
            self = .generate(body)
        } else if let body = try? TopologyBody(from: decoder) {
           self = .topology(body)
        } else if let body = try? BroadcastBody(from: decoder) {
            self = .broadcast(body)
        } else if let body = try? ReadBody(from: decoder) {
            self = .read(body)
        } else {
            fatalError()
        }
    }
}

struct Message: Decodable {
    var src: String
    var dest: String
    var body: MessageBody
}

struct Reply<T: Codable>: Codable {
    var src: String
    var dest: String
    var body: T
}
