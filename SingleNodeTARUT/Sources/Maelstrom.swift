//
//  Maelstrom.swift
//
//
//  Created by Charles Roth on 2024-06-25.
//

import Foundation
import AsyncAlgorithms

struct InitMessage: Codable {
    let type: String
    let node_id: String
    let node_ids: [String]
    let msg_id: Int
}

struct InitOkMessage: Codable {
    let type: String
    let in_reply_to: Int
}

struct TxnOperation: Codable {
    let op: String
    let key: Int
    let value: Int?
    
    init(op: String, key: Int, value: Int?) {
        self.op = op
        self.key = key
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.op = try container.decode(String.self)
        self.key = try container.decode(Int.self)
        self.value = try container.decodeIfPresent(Int.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.op)
        try container.encode(self.key)
        try container.encode(self.value)
    }
}

struct TxnMessage: Codable {
    let type: String
    let msg_id: Int
    let txn: [TxnOperation]
}

struct TxnRpcMessage: Codable {
    let type: String
    var msg_id: Int
    let txn: [TxnOperation]
}

struct TxnOkMessage: Codable {
    let type: String
    let in_reply_to: Int
    let txn: [TxnOperation]
}

struct TxnRpcOkMessage: Codable {
    let type: String
    let in_reply_to: Int
    let txn: [TxnOperation]
}

struct ErrorMessage: Codable {
    let type: String
    let code: Int
    let text: String?
    let in_reply_to: Int?
}

enum RpcMessage {
    case txnRpcMessage(TxnRpcMessage)
}

enum RpcOkMessage {
    case txnRpcOkMessage(TxnRpcOkMessage)
}

enum MessageType: Codable {
    case initMessage(InitMessage)
    case initOkMessage(InitOkMessage)
    case txnMessage(TxnMessage)
    case txnRpcMessage(TxnRpcMessage)
    case txnOkMessage(TxnOkMessage)
    case txnRpcOkMessage(TxnRpcOkMessage)
    case errorMessage(ErrorMessage)

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "init":
            let message = try InitMessage(from: decoder)
            self = .initMessage(message)
        case "init_ok":
            let message = try InitOkMessage(from: decoder)
            self = .initOkMessage(message)
        case "txn":
            let message = try TxnMessage(from: decoder)
            self = .txnMessage(message)
        case "txn_rpc":
            let message = try TxnRpcMessage(from: decoder)
            self = .txnRpcMessage(message)
        case "txn_ok":
            let message = try TxnOkMessage(from: decoder)
            self = .txnOkMessage(message)
        case "txn_rpc_ok":
            let message = try TxnRpcOkMessage(from: decoder)
            self = .txnRpcOkMessage(message)
        case "error":
            let message = try ErrorMessage(from: decoder)
            self = .errorMessage(message)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown message type type"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .initMessage(let message):
            try container.encode(message)
        case .initOkMessage(let message):
            try container.encode(message)
        case .txnMessage(let message):
            try container.encode(message)
        case .txnRpcMessage(let message):
            try container.encode(message)
        case .txnOkMessage(let message):
            try container.encode(message)
        case .txnRpcOkMessage(let message):
            try container.encode(message)
        case .errorMessage(let message):
            try container.encode(message)
        }
    }
}

struct MaelstromMessage: Codable {
    let src: String
    let dest: String
    let body: MessageType
}
