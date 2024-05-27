// swift-tools-version:5.10

import Foundation

class StandardError: TextOutputStream {
  func write(_ string: String) {
    try! FileHandle.standardError.write(contentsOf: Data(string.utf8))
  }
}

struct InitBody: Decodable {
    var type: String
    var msg_id: Int
    var node_id: String
    var node_ids: [String]
}

struct InitReply: Encodable {
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

struct EchoReply: Encodable {
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

enum MessageBody {
    case `init`(InitBody)
    case echo(EchoBody)
}

extension MessageBody: Decodable {
    enum CodingKeys: CodingKey {
        case `init`, echo
    }
    
    init(from decoder: Decoder) throws {
        if let body = try? InitBody(from: decoder) {
            self = .`init`(body)
        } else if let body = try? EchoBody(from: decoder) {
            self = .echo(body)
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

struct Reply<T: Encodable>: Encodable {
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
}


@main
struct FlyDistSwift {
    static func main() async throws {
        // while let input = readLine(strippingNewline: true) {
        // }
        let node = Node()
        let jsonEncoder = JSONEncoder()
        let initMessage = """
        {
          "src": "n1",
          "dest": "n3",
          "body": {
              "type": "init",
              "msg_id": 1,
              "node_id": "n3",
              "node_ids": ["n1", "n2", "n3"]
          }
        }
        """
        let echoMessage = """
        {
          "src": "n1",
          "dest": "n3",
          "body": {
              "type": "echo",
              "msg_id": 2,
              "echo": "Please echo 35"
          }
        }
        """
        let messages = [initMessage, echoMessage]
        for message in messages {
            print("incoming message:\n\(message)")
            let messageData = message.data(using: .utf8)!
            let decodedMessage = try! JSONDecoder().decode(Message.self, from: messageData)
            switch decodedMessage.body {
            case .`init`(let body):
                let reply = await node.handleInit(
                    message: decodedMessage,
                    body: body
                )
                let jsonReply = try jsonEncoder.encode(reply)
                let jsonReplyString = String(data: jsonReply, encoding: .utf8)!
                print("reply: \(jsonReplyString)")
            case .echo(let body):
                let reply = await node.handleEcho(
                    message: decodedMessage,
                    body: body
                )
                let jsonReply = try jsonEncoder.encode(reply)
                let jsonReplyString = String(data: jsonReply, encoding: .utf8)!
                print("reply: \(jsonReplyString)")
            }
            print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
        }
        
    }
}
