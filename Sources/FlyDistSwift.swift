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
    case .topology(let body):
        let reply = await node.handleTopology(
            message: decodedMessage,
            body: body
        )
        return try jsonEncoder.encode(reply)
    case .broadcast(let body):
        let reply = await node.handleBroadcast(
            message: decodedMessage,
            body: body
        )
        return try jsonEncoder.encode(reply)
    case .read(let body):
        let reply = await node.handleRead(
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
