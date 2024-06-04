package internal

import (
	"time"

	m "github.com/jepsen-io/maelstrom/demo/go"
)

type GossipMessage struct {
	Type     string    `json:"type"`
	Messages []float64 `json:"messages"`
}

type Gossiper struct {
	ticker   *time.Ticker
	doneChan chan bool
}

func NewGossiper(tick time.Duration) *Gossiper {
	return &Gossiper{
		ticker:   time.NewTicker(tick),
		doneChan: make(chan bool),
	}
}

func (g *Gossiper) Start(store *Store, node *m.Node, maxNodes int) {
	go func() {
		for {
			select {
			case <-g.doneChan:
				g.ticker.Stop()
				return
			case <-g.ticker.C:
				err := gossip(store, node, maxNodes)
				if err != nil {
					return
				}
			}
		}
	}()
}

func (g Gossiper) Stop() {
	g.doneChan <- true
}

func gossip(store *Store, node *m.Node, maxNodes int) error {
	nodeIds := node.NodeIDs()
	nodesToGossip := GetRandomNodes(nodeIds, maxNodes)
	messages := store.ReadAll()

	message := &GossipMessage{
		Type:     "gossip",
		Messages: messages,
	}

	for _, nodeId := range nodesToGossip {
		if nodeId == node.ID() {
			continue
		}

		go func(dest string) {
			for {
				err := node.Send(dest, message)
				if err == nil {
					break
				}
			}
		}(nodeId)
	}

	return nil
}
