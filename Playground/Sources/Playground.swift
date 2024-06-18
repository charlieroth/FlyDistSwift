//
//  Playground.swift
//
//
//  Created by Charles Roth on 2024-06-16.
//

import Foundation
import ArgumentParser
import DistributedCluster

@main
struct Playground: AsyncParsableCommand {
    @Option(help: "fail every Nth message")
    var failEvery: Int?
    
    mutating func run() async throws {
        let numCycles = 10
        
        // Tree topology
//        let topology: [String:[String]] = [
//            "n0": ["n1", "n2"],
//            "n1": ["n3", "n4", "n0"],
//            "n2": ["n5", "n6", "n0"],
//            "n3": ["n1"],
//            "n4": ["n1"],
//            "n5": ["n2"],
//            "n6": ["n2"],
//        ]
        // Initialize actors
        let coordinator = BroadcastNode(id: "c0")
        let n0 = BroadcastNode(id: "n0")
        let n1 = BroadcastNode(id: "n1")
        let n2 = BroadcastNode(id: "n2")
        let n3 = BroadcastNode(id: "n3")
        let n4 = BroadcastNode(id: "n4")
        let n5 = BroadcastNode(id: "n5")
        let n6 = BroadcastNode(id: "n6")
        
        // Array of all nodes
        let nodes: [BroadcastNode] = [n0, n1, n2, n3, n4, n5, n6]
        
        // Create topological relationships
        await n0.addNeighbor(id: coordinator.id, neighbor: coordinator)
        await n1.addNeighbor(id: coordinator.id, neighbor: coordinator)
        await n2.addNeighbor(id: coordinator.id, neighbor: coordinator)
        await n3.addNeighbor(id: coordinator.id, neighbor: coordinator)
        await n4.addNeighbor(id: coordinator.id, neighbor: coordinator)
        await n5.addNeighbor(id: coordinator.id, neighbor: coordinator)
        await n6.addNeighbor(id: coordinator.id, neighbor: coordinator)
        
        await n0.addNeighbor(id: n1.id, neighbor: n1)
        await n0.addNeighbor(id: n2.id, neighbor: n2)
        await n1.addNeighbor(id: n3.id, neighbor: n3)
        await n1.addNeighbor(id: n4.id, neighbor: n4)
        await n1.addNeighbor(id: n0.id, neighbor: n0)
        await n2.addNeighbor(id: n5.id, neighbor: n5)
        await n2.addNeighbor(id: n6.id, neighbor: n6)
        await n2.addNeighbor(id: n0.id, neighbor: n0)
        await n3.addNeighbor(id: n1.id, neighbor: n1)
        await n4.addNeighbor(id: n1.id, neighbor: n1)
        await n5.addNeighbor(id: n2.id, neighbor: n2)
        await n6.addNeighbor(id: n2.id, neighbor: n2)
        
        // Run system
        // Send 1 message every second, for 10 seconds
        let systemTask = Task {
            var cycle = 0
            while true {
                let randomMessage = Int.random(in: 0..<10000)
                // Get random node
                if let node = nodes.randomElement() {
                    // Send broadcast message
                    try await node.broadcast(
                        message: BroadcastMessage(
                            src: coordinator.id,
                            dest: node.id,
                            msg_id: cycle,
                            message: randomMessage
                        )
                    )
                } else {
                    print("Failed to find random node to broadcast to")
                }
                // Delay
                cycle += 1
                try await Task.sleep(for: .seconds(1))
            }
        }
        
        Task {
            try await Task.sleep(for: .seconds(numCycles))
            systemTask.cancel()
            
            for node in nodes {
                let nodeId = await node.id
                let nodeMessages = await node.messages
                print("\(nodeId): received messages \(nodeMessages)")
            }

            print("System run complete...")
        }

        _ = readLine()
    }
}
