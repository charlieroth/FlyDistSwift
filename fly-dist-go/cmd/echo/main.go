package main

import (
	"encoding/json"
	"fmt"
	"log"

	m "github.com/jepsen-io/maelstrom/demo/go"
)

func main() {
	n := m.NewNode()

	n.Handle("echo", func(msg m.Message) error {
		var body map[string]any
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return fmt.Errorf("unmarshal init message body: %w", err)
		}

		return n.Reply(msg, map[string]any{
			"type": "echo_ok",
			"echo": body["echo"],
		})
	})

	if err := n.Run(); err != nil {
		log.Fatal(err)
	}
}
