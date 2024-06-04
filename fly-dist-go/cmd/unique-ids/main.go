package main

import (
	"encoding/json"
	"log"
	"math"
	"math/rand"
	"time"

	m "github.com/jepsen-io/maelstrom/demo/go"
)

func main() {
	n := m.NewNode()
	n.Handle("generate", func(msg m.Message) error {
		var body map[string]any
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return err
		}

		rand.New(rand.NewSource(time.Now().UnixNano()))
		randomId := rand.Intn(math.MaxInt)

		return n.Reply(msg, map[string]any{
			"type": "generate_ok",
			"id":   randomId,
		})
	})

	if err := n.Run(); err != nil {
		log.Fatal(err)
	}
}
