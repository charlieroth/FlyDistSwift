import Foundation
import Distributed
import DistributedCluster
import ArgumentParser

typealias DefaultDistributedActorSystem = ClusterSystem

distributed public actor PlaygroundNode {
    var neighbors: Set<PlaygroundNode> = Set()
    
    struct Message: Codable {
        var src: String
        var content: String
    }
    
    public init(actorSystem: ClusterSystem) async {
        self.actorSystem = actorSystem
        await actorSystem.receptionist.checkIn(self, with: Self.key)
        
        Task {
            for await node in await actorSystem.receptionist.listing(of: Self.key) {
                actorSystem.log.info("node discovered: \(node.id)")
                self.neighbors.insert(node)
            }
        }
    }
    
    distributed func ping(message: String) async throws {
        if neighbors.isEmpty {
            actorSystem.log.info("No neighbors to ping")
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
        actorSystem.log.info("received: \(message)")
    }
}

extension PlaygroundNode {
    static var key: DistributedReception.Key<PlaygroundNode> { "nodes" }
}

@main
struct Playground: AsyncParsableCommand {
    
    @Option(help: "Port the node will be discoverable at in the cluster (e.g., --port=3333)")
    var port: Int
    
    @Option(help: "Name of the node in the cluster (e.g., ---name=node-a)")
    var name: String
    
    @Option(help: "Comma separated list of ports in the cluster to be formed (e.g., ---cluster-ports=3333,3334,3335)")
    var clusterPorts: String
    
    mutating func run() async throws {
        let system = await ClusterSystem(name) { settings in
            settings.bindHost = "127.0.0.1"
            settings.bindPort = port
        }
        
        let clusterPorts = clusterPorts.split(separator: ",").compactMap { Int($0) }
        if clusterPorts.isEmpty {
            print("invalid --cluster-ports option")
            Self.exit()
        }
        
        for port in clusterPorts {
            system.cluster.join(host: "127.0.0.1", port: port)
        }
        try await system.cluster.joined(within: .seconds(5))
        
        
        Task {
            system.log.info("Listening for cluster events...")
            for await event in system.cluster.events {
                switch event {
                case .snapshot(let memebership):
                    system.log.info("[cluster][snapshot]: \(memebership)")
                    break
                case .membershipChange(let change):
                    system.log.info("[cluster][memberhsip]: \(change)")
                    break
                case .leadershipChange(let change):
                    system.log.info("[cluster][leadership]: \(change)")
                    break
                case .reachabilityChange(let change):
                    system.log.info("[cluster][reachability]: \(change)")
                    break
                default:
                    system.log.info("[cluster]: unhandled event")
                    break
                }
            }
        }
        
        let node = await PlaygroundNode(actorSystem: system)
        Task {
            let randomSleep = Int.random(in: 1000..<2000)
            while true {
                try await node.ping(message: UUID().uuidString)
                try await Task.sleep(for: .milliseconds(randomSleep))
            }
        }
        
        try await system.terminated
    }
}
