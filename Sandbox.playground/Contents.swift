import Foundation

enum SandboxError: Error {
    case failedToAssignKeyToNode
}

var id = "n0"
var nodeIds = ["n0", "n1"]

func keyToNode(key: String) throws -> String {
    if let keyInt = Int(key) {
        let nodeId = keyInt % nodeIds.count
        return "n\(nodeId)"
    }
    
    throw SandboxError.failedToAssignKeyToNode
}

func keysForLocalAndRemote(keys: [String]) throws -> ([String], [String]) {
    let forSelf = try keys.filter { key in
        let nodeId = try keyToNode(key: key)
        return nodeId == id
    }
    
    let forRemote = try keys.filter { key in
        let nodeId = try keyToNode(key: key)
        return nodeId != id
    }
    
    return (forSelf, forRemote)
}

let node = try keyToNode(key: "5")
let (localKeys, remoteKeys) = try keysForLocalAndRemote(keys: ["5"])
localKeys
remoteKeys
