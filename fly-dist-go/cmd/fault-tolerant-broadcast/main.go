package main

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/charlieroth/gossip-gloomers/fly-dist-go/internal"
	m "github.com/jepsen-io/maelstrom/demo/go"
)

func main() {
	n := m.NewNode()
	store := internal.NewStore()
	gossiper := internal.NewGossiper(100 * time.Millisecond)

	n.Handle("topology", func(msg m.Message) error {
		gossiper.Start(store, n, 5)
		return n.Reply(msg, map[string]any{
			"type": "topology_ok",
		})
	})

	n.Handle("gossip", func(msg m.Message) error {
		var body internal.GossipMessage
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return fmt.Errorf("unmarshal init message body: %w", err)
		}

		for _, message := range body.Messages {
			store.Add(message)
		}

		return n.Reply(msg, body)
	})

	n.Handle("broadcast", func(msg m.Message) error {
		var body map[string]any
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return fmt.Errorf("unmarshal init message body: %w", err)
		}

		bodyMsg := body["message"]
		v := bodyMsg.(float64)
		store.Add(v)

		return n.Reply(msg, map[string]any{
			"type": "broadcast_ok",
		})
	})

	n.Handle("read", func(msg m.Message) error {
		var body map[string]any
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return fmt.Errorf("unmarshal init message body: %w", err)
		}

		return n.Reply(msg, map[string]any{
			"type":     "read_ok",
			"messages": store.ReadAll(),
		})
	})

	if err := n.Run(); err != nil {
		gossiper.Stop()
		log.Fatal(err)
	}
}
