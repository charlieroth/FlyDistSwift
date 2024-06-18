//
//  PlaygroundNode.swift
//  
//
//  Created by Charles Roth on 2024-06-17.
//

import Foundation
import Distributed
import DistributedCluster

typealias DefaultDistributedActorSystem = ClusterSystem

enum PlaygroundNodeError: Error {
    case failedToAck
}

struct PlaygroundMessage: Codable {
    var src: String
    var content: String
}

distributed public actor PlaygroundNode {
    var messages: [PlaygroundMessage]
    var neighbors: Set<PlaygroundNode> = Set()
    var failEvery: Int
    
    public init(actorSystem: ClusterSystem, failEvery: Int) async {
        self.messages = []
        self.failEvery = failEvery
        self.actorSystem = actorSystem
        await actorSystem.receptionist.checkIn(self, with: Self.key)
        
        Task {
            for await node in await actorSystem.receptionist.listing(of: Self.key) {
                actorSystem.log.info("node discovered: \(node.id)")
                self.neighbors.insert(node)
            }
        }
    }
    
    distributed func rpc(message: String) async throws {
        if neighbors.isEmpty {
            actorSystem.log.info("No neighbors to ping")
            return
        }
        
        for node in neighbors {
            if node.id == self.id { continue }
            
            Task {
                try await node.send(
                    message: PlaygroundMessage(
                        src: "\(actorSystem.cluster.endpoint.port):\(self.id.name)",
                        content: message
                    )
                )
            }
        }
    }
    
    distributed func send(message: PlaygroundMessage) async -> Void {
        actorSystem.log.info("received: \(message)")
        self.messages.append(message)
    }
    
    distributed func rpc(message: PlaygroundMessage) async throws {
        actorSystem.log.info("received: \(message)")
        if (self.messages.count % self.failEvery == 0) {
            actorSystem.log.info("\(actorSystem.cluster.endpoint.port):\(self.id.name) - failed to process message")
            throw PlaygroundNodeError.failedToAck
        }
        
        self.messages.append(message)
    }
}

extension PlaygroundNode {
    static var key: DistributedReception.Key<PlaygroundNode> { "nodes" }
}
