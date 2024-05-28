// swift-tools-version:5.10

import Foundation

class StandardError: TextOutputStream {
    func write(_ string: String) {
        try! FileHandle.standardError.write(contentsOf: Data(string.utf8))
    }
}

class StandardOut: TextOutputStream {
    func write(_ string: String) {
        try! FileHandle.standardOutput.write(contentsOf: Data(string.utf8))
    }
}

struct InitBody: Decodable {
    var type: String
    var msg_id: Int
    var node_id: String
    var node_ids: [String]
}

struct InitReply: Codable {
    var type: String
    var in_reply_to: Int
    var msg_id: Int
    
    init(type: String, in_reply_to: Int) {
        self.type = type
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
    
    init(type: String, in_reply_to: Int, echo: String) {
        self.type = type
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
    
    init(type: String, in_reply_to: Int) {
        self.type = type
        self.in_reply_to = in_reply_to
        self.id = Int(arc4random())
        self.msg_id = Int(arc4random())
    }
}

enum MessageBody {
    case `init`(InitBody)
    case echo(EchoBody)
    case generate(GenerateBody)
}

extension MessageBody: Decodable {
    enum CodingKeys: CodingKey {
        case `init`, echo, generate
    }
    
    init(from decoder: Decoder) throws {
        if let body = try? InitBody(from: decoder) {
            self = .`init`(body)
        } else if let body = try? EchoBody(from: decoder) {
            self = .echo(body)
        } else if let body = try? GenerateBody(from: decoder) {
            self = .generate(body)
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

actor Node {
    var id: String? = nil
    var nodes: [String]? = nil
    
    func handleInit(message: Message, body: InitBody) -> Reply<InitReply> {
        self.id = body.node_id
        self.nodes = body.node_ids
        
        return Reply<InitReply>(
            src: body.node_id,
            dest: message.src,
            body: InitReply(
                type: "init_ok",
                in_reply_to: body.msg_id
            )
        )
    }
    
    func handleEcho(message: Message, body: EchoBody) -> Reply<EchoReply> {
        return Reply<EchoReply>(
            src: self.id!,
            dest: message.src,
            body: EchoReply(
                type: "echo_ok",
                in_reply_to: body.msg_id,
                echo: body.echo
            )
        )
    }
    
    func handleGenerate(message: Message, body: GenerateBody) -> Reply<GenerateReply> {
        return Reply<GenerateReply>(
            src: self.id!,
            dest: message.src,
            body: GenerateReply(type: "generate_ok", in_reply_to: body.msg_id)
        )
    }
}

func handleMessage(message: String, node: Node, stderr: StandardError) async throws -> Data {
    let jsonEncoder = JSONEncoder()
    stderr.write("received: \(message)")
    let messageData = message.data(using: .utf8)!
    let decodedMessage = try! JSONDecoder().decode(Message.self, from: messageData)
    switch decodedMessage.body {
    case .`init`(let body):
        let reply = await node.handleInit(
            message: decodedMessage,
            body: body
        )
        return try jsonEncoder.encode(reply)
    case .echo(let body):
        let reply = await node.handleEcho(
            message: decodedMessage,
            body: body
        )
        return try jsonEncoder.encode(reply)
    case .generate(let body):
        let reply = await node.handleGenerate(
            message: decodedMessage,
            body: body
        )
        return try jsonEncoder.encode(reply)
    }
}


@main
struct FlyDistSwift {
    static func main() async throws {
        let stderr = StandardError()
        let stdout = StandardOut()
        let node = Node()
        stderr.write("in main loop")
         while let message = readLine(strippingNewline: true) {
            stderr.write("received: \(message)")
            let jsonReply = try await handleMessage(message: message, node: node, stderr: stderr)
            let jsonReplyString = String(data: jsonReply, encoding: .utf8)!
            stderr.write("reply: \(jsonReplyString)")
            stdout.write(jsonReplyString)
            stdout.write("\n")
        }
    }
}
