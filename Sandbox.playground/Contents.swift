import Foundation

var tasks: [Int:Bool] = [:]

tasks[1] = false
tasks[2] = true

print(tasks.count)

tasks.removeValue(forKey: 1)

print(tasks.count)
