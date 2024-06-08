import Foundation

@main
struct Echo {
    static func main() async throws {
        let stderr = StandardError()
        let node = Node()
        while let line = readLine(strippingNewline: true) {
            let data = line.data(using: .utf8)!
            let decoder = JSONDecoder()
            let message = try decoder.decode(MaelstromMessage.self, from: data)
            stderr.write("received: \(message)\n")
            switch message.body {
            case .initMessage(let initMessage):
                try await node.handleInit(message: message, body: initMessage)
            case .echoMessage(let echoMessage):
                try await node.handleEcho(message: message, body: echoMessage)
            default:
                stderr.write("no message handler for type: \(message.body.type)\n")
            }
        }
    }
}

