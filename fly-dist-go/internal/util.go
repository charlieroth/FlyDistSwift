package internal

import (
	"math/rand"
	"time"
)

func GetRandomNodes(nodeIDs []string, num int) []string {
	if len(nodeIDs) <= num {
		return nodeIDs
	}

	s := rand.NewSource(time.Now().Unix())
	r := rand.New(s)

	var nodes []string
	for i := 0; i < num; i++ {
		id := r.Intn(len(nodeIDs))
		nodes = append(nodes, nodeIDs[id])
	}
	return nodes
}
