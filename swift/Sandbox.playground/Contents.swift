import Foundation

var setA: Set<Int> = [1, 2, 3, 4]
var setB: Set<Int> = [3, 4, 5, 6]

setA == setB

let addToB = setA.subtracting(setB)
let addToA = setB.subtracting(setA)

setA.formUnion(addToA)
setB.formUnion(addToB)

setA == setB

var setC: Set<Int> = [1, 2, 3, 4, 5]

setA.subtracting(setC)
