//
//  Maelstrom.swift
//
//
//  Created by Charles Roth on 2024-06-19.
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

struct SendMessage: Codable {
    var type: String
    var key: String
    var msg: Int
    var msg_id: Int
}

struct SendOkMessage: Codable {
    var type: String
    var offset: Int
    var msg_id: Int?
    var in_reply_to: Int
}

struct PollMessage: Codable {
    var type: String
    var offsets: [String:Int]
    var msg_id: Int
}

struct PollOkMessage: Codable {
    var type: String
    var msgs: [String:[[Int]]]
    var msg_id: Int?
    var in_reply_to: Int
}

struct CommitOffsetsMessage: Codable {
    var type: String
    var offsets: [String:Int]
    var msg_id: Int
}

struct CommitOffsetsOkMessage: Codable {
    var type: String
    var msg_id: Int?
    var in_reply_to: Int
}

struct ListCommittedOffsetsMessage: Codable {
    var type: String
    var keys: [String]
    var msg_id: Int
}

struct ListCommittedOffsetsOkMessage: Codable {
    var type: String
    var offsets: [String:Int]
    var msg_id: Int?
    var in_reply_to: Int
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
    case errorMessage(ErrorMessage)
    case pollMessage(PollMessage)
    case pollOkMessage(PollOkMessage)
    case sendMessage(SendMessage)
    case sendOkMessage(SendOkMessage)
    case commitOffsetsMessage(CommitOffsetsMessage)
    case commitOffsetsOkMessage(CommitOffsetsOkMessage)
    case listCommittedOffsetsMessage(ListCommittedOffsetsMessage)
    case listCommittedOffsetsOkMessage(ListCommittedOffsetsOkMessage)

    var type: String {
        switch self {
        case .initMessage: return "init"
        case .initOkMessage: return "init_ok"
        case .errorMessage: return "error"
        case .sendMessage: return "send"
        case .sendOkMessage: return "send_ok"
        case .pollMessage: return "poll"
        case .pollOkMessage: return "poll_ok"
        case .commitOffsetsMessage: return "commit_offsets"
        case .commitOffsetsOkMessage: return "commit_offsets_ok"
        case .listCommittedOffsetsMessage: return "list_committed_offsets"
        case .listCommittedOffsetsOkMessage: return "list_committed_offsets_ok"
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
        case "error":
            let decodedMessage = try jsonDecoder.decode(
                ErrorMessage.self,
                from: jsonData
            )
            self = .errorMessage(decodedMessage)
        case "send":
            let decodedMessage = try jsonDecoder.decode(
                SendMessage.self,
                from: jsonData
            )
            self = .sendMessage(decodedMessage)
        case "send_ok":
            let decodedMessage = try jsonDecoder.decode(
                SendOkMessage.self,
                from: jsonData
            )
            self = .sendOkMessage(decodedMessage)
        case "poll":
            let decodedMessage = try jsonDecoder.decode(
                PollMessage.self,
                from: jsonData
            )
            self = .pollMessage(decodedMessage)
        case "poll_ok":
            let decodedMessage = try jsonDecoder.decode(
                PollOkMessage.self,
                from: jsonData
            )
            self = .pollOkMessage(decodedMessage)
        case "commit_offsets":
            let decodedMessage = try jsonDecoder.decode(
                CommitOffsetsMessage.self,
                from: jsonData
            )
            self = .commitOffsetsMessage(decodedMessage)
        case "commit_offsets_ok":
            let decodedMessage = try jsonDecoder.decode(
                CommitOffsetsOkMessage.self,
                from: jsonData
            )
            self = .commitOffsetsOkMessage(decodedMessage)
        case "list_committed_offsets":
            let decodedMessage = try jsonDecoder.decode(
                ListCommittedOffsetsMessage.self,
                from: jsonData
            )
            self = .listCommittedOffsetsMessage(decodedMessage)
        case "list_committed_offsets_ok":
            let decodedMessage = try jsonDecoder.decode(
                ListCommittedOffsetsOkMessage.self,
                from: jsonData
            )
            self = .listCommittedOffsetsOkMessage(decodedMessage)
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
        case .sendMessage(let message):
            try container.encode(message)
        case .sendOkMessage(let message):
            try container.encode(message)
        case .pollMessage(let message):
            try container.encode(message)
        case .pollOkMessage(let message):
            try container.encode(message)
        case .commitOffsetsMessage(let message):
            try container.encode(message)
        case .commitOffsetsOkMessage(let message):
            try container.encode(message)
        case .listCommittedOffsetsMessage(let message):
            try container.encode(message)
        case .listCommittedOffsetsOkMessage(let message):
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
