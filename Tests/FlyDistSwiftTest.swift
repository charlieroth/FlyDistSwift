//
//  FlyDistSwiftTest.swift
//  
//
//  Created by Charlie Roth on 2024-05-28.
//


import XCTest
@testable import FlyDistSwift

final class FlyDistSwiftTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitMessageSequence() async throws {
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let node = Node()
        let stderr = StandardError()
        
        let initMessage = """
        {
          "src": "n1",
          "dest": "n3",
          "body": {
              "type": "init",
              "msg_id": 1,
              "node_id": "n3",
              "node_ids": ["n1", "n2", "n3"]
          }
        }
        """
        let jsonReply = try await handleMessage(message: initMessage, node: node, stderr: stderr)
        let _ = try JSONDecoder().decode(Reply<EchoReply>.self, from: jsonReply)
        
        let nodeId = await node.id
        XCTAssert(nodeId == "n3")
        
        let nodeIds = await node.nodes
        XCTAssert(nodeIds == ["n1", "n2", "n3"])
    }
}
