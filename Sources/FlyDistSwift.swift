import Foundation

struct InitMessageBody: Decodable {
    var type: String
    var msg_id: Int
    var node_id: String
    var node_ids: [String]
}

struct MessageBody: Decodable {
    var type: String
    var msg_id: String?
    var in_reply_to: String?
}

struct Message<T: Decodable>: Decodable {
    var src: String
    var dest: String
    var body: T
}

actor Node {
    var id: Int
    var nodes: [String]
    
    init(id: Int, nodes: [String]) {
        self.id = id
        self.nodes = nodes
    }
}


@main
struct FlyDistSwift {
    static func main() {
        // let input = readLine(strippingNewline: true)!
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
        
        // Parsing JSON into a dictionary
        guard let data = initMessage.data(using: .utf8),
              let parsedJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:[String:Any]] else {
            fatalError("Failed to parse JSON")
        }
        
//        while let input = readLine(strippingNewline: true) {
//            let inputData = input.data(using: .utf8)!
//            let decodedInitMessage = try? JSONDecoder().decode(Message<InitMessageBody>.self, from: inputData)
//            if decodedInitMessage == nil {
//                
//            }
//        }
        
        let initMessageJSON = initMessage.data(using: .utf8)!
        let decodedInitMessage = try! JSONDecoder().decode(Message<InitMessageBody>.self, from: initMessageJSON)
        print(decodedInitMessage)
    }
}
