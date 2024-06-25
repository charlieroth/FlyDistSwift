import Foundation

// Define the structures for different message types
struct InitMessage: Codable {
    let type: String
    let node_id: String
    let node_ids: [String]
    let msg_id: Int
}

struct InitOkMessage: Codable {
    let type: String
    let msg_id: Int?
    let in_reply_to: Int
}

struct TxnOperation: Codable {
    let op: String
    let key: Int
    let value: Int?
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        op = try container.decode(String.self)
        key = try container.decode(Int.self)
        value = try container.decodeIfPresent(Int.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(op)
        try container.encode(key)
        try container.encode(value)
    }
}

struct TxnMessage: Codable {
    let type: String
    let msg_id: Int
    let txn: [TxnOperation]
}

struct TxnOkMessage: Codable {
    let type: String
    let msg_id: Int?
    let in_reply_to: Int
    let txn: [TxnOperation]
}

struct ErrorMessage: Codable {
    let type: String
    let code: Int
    let text: String?
    let in_reply_to: Int?
}

// Define the MessageType enum
enum MessageType: Codable {
    case initMessage(InitMessage)
    case initOkMessage(InitOkMessage)
    case txnMessage(TxnMessage)
    case txnOkMessage(TxnOkMessage)
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
        case "txn_ok":
            let message = try TxnOkMessage(from: decoder)
            self = .txnOkMessage(message)
        case "error":
            let message = try ErrorMessage(from: decoder)
            self = .errorMessage(message)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown message type")
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
        case .txnOkMessage(let message):
            try container.encode(message)
        case .errorMessage(let message):
            try container.encode(message)
        }
    }
}

// Define the MaelstromMessage struct
struct MaelstromMessage: Codable {
    let src: String
    let dest: String
    let body: MessageType
}

// Function to parse JSON
func parseJSON(_ jsonString: String) throws -> MaelstromMessage {
    let jsonData = jsonString.data(using: .utf8)!
    let decoder = JSONDecoder()
    return try decoder.decode(MaelstromMessage.self, from: jsonData)
}

// Test the parsing
do {
    let json = """
    {"id":4,"src":"c3","dest":"n0","body":{"txn":[["r",9,null]],"type":"txn","msg_id":1}}
    """
    
    let message = try parseJSON(json)
    print("Parsed successfully:")
    print("Source: \(message.src)")
    print("Destination: \(message.dest)")
    
    if case .txnMessage(let txnMsg) = message.body {
        print("Message Type: \(txnMsg.type)")
        print("Message ID: \(txnMsg.msg_id)")
        print("Transactions:")
        for (index, operation) in txnMsg.txn.enumerated() {
            print("[\(operation.op),\(operation.key),\(operation.value)]")
        }
    }
} catch {
    print("Error parsing JSON: \(error)")
}
