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
	
	n.Handle("topology", func(msg m.Message) error {
		var body m.TopologyMessageBody
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return fmt.Errorf("unmarshal init message body: %w", err)
		}

		n.InitTopology(body.Topology)
		log.Printf("Node %s topology initialized", n.Id())

		return n.Send(msg.Src, m.MessageBody{
			InReplyTo: body.MsgId,
			Type: "topology_ok",
		})
	})
	
	n.Handle("broadcast", func(msg m.Message) error {
		var body m.BroadcastMessageBody
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return fmt.Errorf("unmarshal init message body: %w", err)
		}

		n.SaveMessage(body.Message)

		return n.Send(msg.Src, m.MessageBody{
			InReplyTo: body.MsgId,
			Type: "broadcast_ok",
		})
	})
	
	n.Handle("read", func(msg m.Message) error {
		var body m.MessageBody
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return fmt.Errorf("unmarshal init message body: %w", err)
		}

		messages := n.Messages()

		return n.Send(msg.Src, m.ReadMessageBody{
			MessageBody: m.MessageBody{
				InReplyTo: body.MsgId,
				Type: "read_ok",
			},
			Messages: messages,
		})
	})
	// execute node's message loop. runs untils stdin is closed
	if err := n.Run(); err != nil {
		log.Printf("ERROR: %s", err)
		os.Exit(1)
	}
}


