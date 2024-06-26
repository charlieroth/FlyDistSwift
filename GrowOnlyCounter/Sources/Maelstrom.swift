//
//  Maelstrom.swift
//
//
//  Created by Charles Roth on 2024-06-18.
//

import Foundation
import AsyncAlgorithms

struct InitMessage: Codable {
    var type: String
    var node_id: String
    var node_ids: [String]
    var msg_id: Int
}

struct InitOkMessage: Codable {
    var type: String
    var msg_id: Int?
    var in_reply_to: Int
}

struct ReadMessage: Codable {
    var type: String
    var msg_id: Int
}

struct ReadOkMessage: Codable {
    var type: String
    var value: Int
    var msg_id: Int?
    var in_reply_to: Int
}

struct AddMessage: Codable {
    var type: String
    var delta: Int
    var msg_id: Int
}

struct AddOkMessage: Codable {
    var type: String
    var msg_id: Int?
    var in_reply_to: Int
}

struct GossipMessage: Codable {
    var type: String
    var counters: [String:Counter]
}

struct ErrorMessage: Codable {
    var type: String
    var code: Int
    var text: String?
    var in_reply_to: Int?
}

enum MessageType: Codable {
    case initMessage(InitMessage)
    case initOkMessage(InitOkMessage)
    case readMessage(ReadMessage)
    case readOkMessage(ReadOkMessage)
    case addMessage(AddMessage)
    case addOkMessage(AddOkMessage)
    case gossipMessage(GossipMessage)
    case errorMessage(ErrorMessage)

    var type: String {
        switch self {
        case .initMessage: return "init"
        case .initOkMessage: return "init_ok"
        case .readMessage: return "read"
        case .readOkMessage: return "read_ok"
        case .addMessage: return "add"
        case .addOkMessage: return "add_ok"
        case .gossipMessage: return "gossip"
        case .errorMessage: return "error"
        }
    }

    // Decoding logic for different message types
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValue = try container.decode(AnyCodable.self).value as! [String: Any]
        let type = decodedValue["type"] as! String

        let jsonData = try JSONSerialization.data(withJSONObject: decodedValue)
        let jsonDecoder = JSONDecoder()

        switch type {
        case "init":
            let decodedMessage = try jsonDecoder.decode(
                InitMessage.self,
                from: jsonData
            )
            self = .initMessage(decodedMessage)
        case "init_ok":
            let decodedMessage = try jsonDecoder.decode(
                InitOkMessage.self,
                from: jsonData
            )
            self = .initOkMessage(decodedMessage)
        case "read":
            let decodedMessage = try jsonDecoder.decode(
                ReadMessage.self,
                from: jsonData
            )
            self = .readMessage(decodedMessage)
        case "read_ok":
            let decodedMessage = try jsonDecoder.decode(
                ReadOkMessage.self,
                from: jsonData
            )
            self = .readOkMessage(decodedMessage)
        case "add":
            let decodedMessage = try jsonDecoder.decode(
                AddMessage.self,
                from: jsonData
            )
            self = .addMessage(decodedMessage)
        case "add_ok":
            let decodedMessage = try jsonDecoder.decode(
                AddOkMessage.self,
                from: jsonData
            )
            self = .addOkMessage(decodedMessage)
        case "gossip":
            let decodedMessage = try jsonDecoder.decode(
                GossipMessage.self,
                from: jsonData
            )
            self = .gossipMessage(decodedMessage)
        case "error":
            let decodedMessage = try jsonDecoder.decode(
                ErrorMessage.self,
                from: jsonData
            )
            self = .errorMessage(decodedMessage)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid type"
                )
            )
        }
    }

    // Encoding logic for different message types
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .initMessage(let message):
            try container.encode(message)
        case .initOkMessage(let message):
            try container.encode(message)
        case .readMessage(let message):
            try container.encode(message)
        case .readOkMessage(let message):
            try container.encode(message)
        case .addMessage(let message):
            try container.encode(message)
        case .addOkMessage(let message):
            try container.encode(message)
        case .gossipMessage(let message):
            try container.encode(message)
        case .errorMessage(let message):
            try container.encode(message)
        }
    }
}

// Base structure for a Maelstrom message
struct MaelstromMessage: Codable {
    let src: String
    let dest: String
    let body: MessageType
}

// Utility to handle any type of value in JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let arrayValue = value as? [Any] {
            let codableArray = arrayValue.map { AnyCodable($0) }
            try container.encode(codableArray)
        } else if let dictionaryValue = value as? [String: Any] {
            let codableDictionary = dictionaryValue.mapValues { AnyCodable($0) }
            try container.encode(codableDictionary)
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to encode value"))
        }
    }
}
