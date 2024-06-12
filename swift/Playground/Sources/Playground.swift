import Foundation

import Distributed
import DistributedCluster



distributed actor Node {
    typealias ActorSystem = ClusterSystem
    
    var name: UUID
    var count: Int
    var clusterState: [UUID:Int]
    
    init(name: UUID, actorSystem: ActorSystem) {
        self.name = name
        self.count = 0
        self.clusterState = [:]
        self.actorSystem = actorSystem
    }
    
    distributed func increment() async throws -> Int {
        self.count += 1
        print("\(self.name)[inc]: \(self.count)")
        return self.count
    }
    
    distributed func update(who nodeId: UUID, with nodeCount: Int) -> Void {
        print("\(self.name)[update]: \(nodeId), \(nodeCount)")
        self.clusterState[nodeId] = nodeCount
    }
}

extension DistributedReception.Key {
    static var nodes: DistributedReception.Key<Node> {
        "nodes"
    }
}

@main
struct Playground {
    static func main() async throws {
        let system = await ClusterSystem("FirstSystem") { settings in
            settings.endpoint.host = "127.0.0.1"
            settings.endpoint.port = 4269
        }
        
        Task {
            for await event in system.cluster.events {
                switch event {
                case .snapshot(let membership):
                    print("[cluster][snapshot]: \(membership)")
                    break
                case .membershipChange(let change):
                    print("[cluster][membership-change]: \(change)")
                    break
                case .reachabilityChange(let change):
                    print("[cluster][reachability-change]: \(change)")
                    break
                case .leadershipChange(let change):
                    print("[cluster][leadership-change]: \(change)")
                    break
                default:
                    print("[cluster][unknown]")
                    break
                }
            }
        }
        
//        let nodeName = UUID()
//        let node = Node(name: nodeName, actorSystem: system)
//        await system.receptionist.checkIn(node, with: .nodes)
//        
//        let runTask = Task {
//            while true {
//                let newCount = try await node.increment()
//                for await neighbor in await system.receptionist.listing(of: .nodes) {
//                    try await neighbor.update(who: nodeName, with: newCount)
//                }
//                try await Task.sleep(for: .seconds(1))
//            }
//        }
//        
//        Task {
//            try await Task.sleep(for: .seconds(30))
//            runTask.cancel()
//            try system.shutdown()
//        }
//        
//        print("Node \(nodeName) up and running")

        try await system.terminated
    }
}
