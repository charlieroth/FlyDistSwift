//
//  Maelstrom.swift
//
//
//  Created by Charles Roth on 2024-06-08.
//

import Foundation

struct InitMessage: Codable {
    let type: String
    let msg_id: Int
    let node_id: String
    let node_ids: [String]
}

struct InitOkMessage: Codable {
    let type: String
    let in_reply_to: Int
    let msg_id: Int?
}

struct GenerateMessage: Codable {
    let type: String
    let msg_id: Int
}

struct GenerateOkMessage: Codable {
    let type: String
    let in_reply_to: Int
    let msg_id: Int?
    let id: UUID
}

struct ErrorMessage: Codable {
    let type: String
    let in_reply_to: Int
    let code: Int
    let text: String?
}

enum MessageType: Codable {
    case initMessage(InitMessage)
    case initOkMessage(InitOkMessage)
    case generateMessage(GenerateMessage)
    case generateOkMessage(GenerateOkMessage)
    case errorMessage(ErrorMessage)

    var type: String {
        switch self {
        case .initMessage: return "init"
        case .initOkMessage: return "init_ok"
        case .generateMessage: return "generate"
        case .generateOkMessage: return "generate_ok"
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
        case "generate":
            let decodedMessage = try jsonDecoder.decode(
                GenerateMessage.self,
                from: jsonData
            )
            self = .generateMessage(decodedMessage)
        case "generate_ok":
            let decodedMessage = try jsonDecoder.decode(
                GenerateOkMessage.self,
                from: jsonData
            )
            self = .generateOkMessage(decodedMessage)
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
        case .generateMessage(let message):
            try container.encode(message)
        case .generateOkMessage(let message):
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

