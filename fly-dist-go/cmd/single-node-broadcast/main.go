package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	m "github.com/charlieroth/gossip-gloomers/fly-dist-go/maelstrom"
)

func main() {
	n := m.NewNode()

	n.Handle("init", func(msg m.Message) error {
		var body m.InitMessageBody
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return fmt.Errorf("unmarshal init message body: %w", err)
		}

		n.Init(body.NodeId, body.NodeIds)
		log.Printf("Node %s initialized", n.Id())

		return n.Send(msg.Src, m.InitMessageBody{
			MessageBody: m.MessageBody{
				InReplyTo: body.MsgId,
				Type: "init_ok",
			},
		})
	})

	// execute node's message loop. runs untils stdin is closed
	if err := n.Run(); err != nil {
		log.Printf("ERROR: %s", err)
		os.Exit(1)
	}
}


