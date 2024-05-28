//
//  Rpc.swift
//
//
//  Created by Charlie Roth on 2024-05-28.
//

import Foundation

struct InitBody {
    var type: String
    var msg_id: Int
    var node_id: String
    var node_ids: [String]
}

extension InitBody: Decodable {
    enum CodingKeys: CodingKey {
        case type, msg_id, node_id, node_ids
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeValue = try container.decode(String.self, forKey: .type)
        if typeValue != "init" {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Message body must have type 'init'"
            )
        } else {
            self.type = typeValue
        }
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

struct EchoBody {
    var type: String
    var msg_id: Int
    var echo: String
}

extension EchoBody: Decodable {
    enum CodingKeys: CodingKey {
        case type, msg_id, echo
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeValue = try container.decode(String.self, forKey: .type)
        if typeValue != "echo" {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Message body must have type 'echo'"
            )
        } else {
            self.type = typeValue
        }
        self.msg_id = try container.decode(Int.self, forKey: .msg_id)
        self.echo = try container.decode(String.self, forKey: .echo)
    }
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

struct GenerateBody {
    var type: String
    var msg_id: Int
}

extension GenerateBody: Decodable {
    enum CodingKeys: CodingKey {
        case type, msg_id
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeValue = try container.decode(String.self, forKey: .type)
        if typeValue != "generate" {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Message body must have type 'generate'"
            )
        } else {
            self.type = typeValue
        }
        self.msg_id = try container.decode(Int.self, forKey: .msg_id)
    }
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
struct TopologyBody {
    var type: String
    var msg_id: Int
    var topology: [String:[String]]
}

extension TopologyBody: Decodable {
    enum CodingKeys: CodingKey {
        case type, msg_id, topology
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeValue = try container.decode(String.self, forKey: .type)
        if typeValue != "topology" {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Message body must have type 'topology'"
            )
        } else {
            self.type = typeValue
        }
        self.msg_id = try container.decode(Int.self, forKey: .msg_id)
        self.topology = try container.decode([String:[String]].self, forKey: .topology)
    }
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
struct BroadcastBody: Codable {
    var type: String
    var message: Int
    var msg_id: Int
    
    enum CodingKeys: String, CodingKey {
        case type, message, msg_id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.msg_id = try container.decode(Int.self, forKey: .msg_id)
        self.message = try container.decode(Int.self, forKey: .message)
        
        let typeValue = try container.decode(String.self, forKey: .type)
        if typeValue != "broadcast" {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Message body must have type 'broadcast'"
            )
        } else {
            self.type = typeValue
        }
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
struct ReadBody {
    var type: String
    var msg_id: Int
}

extension ReadBody: Decodable {
    enum CodingKeys: CodingKey {
        case type, msg_id
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeValue = try container.decode(String.self, forKey: .type)
        if typeValue != "read" {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Message body must have type 'read'"
            )
        } else {
            self.type = typeValue
        }
        self.msg_id = try container.decode(Int.self, forKey: .msg_id)
    }
}

struct ReadReply: Codable {
    var type: String
    var messages: [Int]
    var in_reply_to: Int
    var msg_id: Int
    
    init(in_reply_to: Int, messages: [Int]) {
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
    enum CodingKeys: String, CodingKey {
        case `init`
        case echo
        case generate
        case topology
        case broadcast
        case read
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
