// swift-tools-version:5.10

import Foundation

func handleMessage(message: String, node: Node, stderr: StandardError) async throws -> Data? {
    let jsonEncoder = JSONEncoder()
    stderr.write("received: \(message)\n")
    let messageData = message.data(using: .utf8)!
    guard let decodedMessage = try? JSONDecoder().decode(Message.self, from: messageData) else {
        return nil
    }
    
    switch decodedMessage.body {
    case .topology(let body):
        let reply = await node.handleTopology(
            message: decodedMessage,
            body: body
        )
        return try jsonEncoder.encode(reply)
    case .broadcast(let body):
        let reply = try await node.handleBroadcast(
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
    case .generate(let body):
        let reply = await node.handleGenerate(
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
    case .`init`(let body):
        let reply = await node.handleInit(
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
        let node = Node(stderr: stderr, stdout: stdout)
        stderr.write("in main loop\n")
         while let message = readLine(strippingNewline: true) {
            guard let jsonReply = try await handleMessage(message: message, node: node, stderr: stderr) else {
                 stderr.write("unsupported message: \(message)\n")
                 continue
            }
            stderr.write("received: \(message)\n")
            let jsonReplyString: String = String(data: jsonReply, encoding: .utf8)!
            stderr.write("reply: \(jsonReplyString)\n")
            stdout.write("\(jsonReplyString)\n")
        }
    }
}
