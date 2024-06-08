// swift-tools-version:5.10

import Foundation

@main
struct FlyDistSwift {
    static func main() async throws {
        let stderr = StandardError()
        let stdout = StandardOut()
        let node = Node(stderr: stderr, stdout: stdout)
        while let line = readLine(strippingNewline: true) {
            let data = line.data(using: .utf8)!
            let decoder = JSONDecoder()
            let message = try decoder.decode(MaelstromMessage.self, from: data)
            stderr.write("received: \(message)")
            handleMessage(message: message, node: node)
        }
    }
}

func handleMessage(message: MaelstromMessage, node: Node) async throws {
    switch message.body.type {
    case .initMessage(let initMessage):
        
    }
}
