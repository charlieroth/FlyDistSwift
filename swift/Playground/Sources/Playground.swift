import Foundation
import Distributed
import DistributedCluster
import ArgumentParser

typealias DefaultDistributedActorSystem = ClusterSystem

distributed public actor PlaygroundNode {
    var neighbors: [PlaygroundNode] = []
    
    struct Message: Codable {
        var src: String
        var content: String
    }
    
    public init(actorSystem: ClusterSystem) async {
        self.actorSystem = actorSystem
        await actorSystem.receptionist.checkIn(self, with: Self.key)
    }
    
    distributed func listen() async throws {
        for await node in await actorSystem.receptionist.listing(of: Self.key) {
            print("\(actorSystem.cluster.endpoint): node joined, \(node.id)")
            self.neighbors.append(node)
        }
    }
    
    distributed func ping(message: String) async throws {
        if neighbors.isEmpty { return }
        
        for node in neighbors {
            if node.id == self.id {
                continue
            }
            
            try await node.pong(
                message: Message(
                    src: "\(actorSystem.cluster.endpoint.port):\(self.id.name)",
                    content: message
                )
            )
        }
    }
    
    distributed func pong(message: Message) async {
        print("\(self.id.name): received \(message)")
    }
}

extension PlaygroundNode {
    static var key: DistributedReception.Key<PlaygroundNode> { "nodes" }
}

func ensureCluster(_ systems: ClusterSystem..., within: Duration) async throws {
    let nodes = Set(systems.map(\.settings.bindNode))
    try await withThrowingTaskGroup(of: Void.self) { group in
        for system in systems {
            group.addTask {
                try await system.cluster.waitFor(nodes, .up, within: within)
            }
        }
        // loop explicitly to propagagte any error that might have been thrown
        for try await _ in group {
            
        }
    }
}

@main
struct Playground: AsyncParsableCommand {
    @Option
    var port: Int
    
    @Option
    var masterPort: Int?
    
    @Option
    var name: String
    
    mutating func run() async throws {
        let playgroundNode = await ClusterSystem(name) { settings in
            settings.bindHost = "127.0.0.1"
            settings.bindPort = port
        }
        
        if (masterPort != nil) {
            playgroundNode.cluster.join(host: "127.0.0.1", port: masterPort!)
            try await ensureCluster(playgroundNode, within: .seconds(10))
        }
        
        let nodeA = await PlaygroundNode(actorSystem: playgroundNode)
        
        Task {
            try await nodeA.listen()
        }
        
        Task {
            while true {
                try await nodeA.ping(message: UUID().uuidString)
                try await Task.sleep(for: .seconds(1))
            }
        }
        
        try await playgroundNode.terminated
    }
}
