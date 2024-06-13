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
        
        Task {
            for await node in await actorSystem.receptionist.listing(of: Self.key) {
                print("\(actorSystem.cluster.endpoint): node joined, \(node.id)")
                self.neighbors.append(node)
            }
        }
    }
    
    distributed func ping(message: String) async throws {
        if neighbors.isEmpty {
            print("\(actorSystem.cluster.endpoint.port):[\(self.id.name)] No neighbors to ping")
            return
        }
        
        for node in neighbors {
            if node.id == self.id { continue }
            
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
        for try await _ in group {}
    }
}

@main
struct Playground: AsyncParsableCommand {
    @Option var port: Int
    @Option var seedPort: Int?
    @Option var name: String
    
    mutating func run() async throws {
        let system = await ClusterSystem(name) { settings in
            settings.bindHost = "127.0.0.1"
            settings.bindPort = port
        }
        
        if (seedPort != nil) {
            system.cluster.join(host: "127.0.0.1", port: seedPort!)
            try await ensureCluster(system, within: .seconds(10))
        }
        
        let nodeA = await PlaygroundNode(actorSystem: system)
        
        let pingTask = Task {
            let randomSleep = Int.random(in: 500..<1000)
            while true {
                try await nodeA.ping(message: UUID().uuidString)
                try await Task.sleep(for: .milliseconds(randomSleep))
            }
        }
        
        Task {
            try await Task.sleep(for: .seconds(20))
            pingTask.cancel()
            try system.shutdown()
        }
        
        try await system.terminated
    }
}
