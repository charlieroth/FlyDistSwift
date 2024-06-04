package main

import (
	"encoding/json"
	"fmt"
	"log"

	m "github.com/charlieroth/gossip-gloomers/fly-dist-go/maelstrom"
)

type Server struct {
	n *m.Node
}

func (s *Server) initHandler(msg m.Message) error {
	var body m.InitMessageBody
	if err := json.Unmarshal(msg.Body, &body); err != nil {
		return fmt.Errorf("unmarshal init message body: %w", err)
	}

	s.n.Init(body.NodeId, body.NodeIds)
	log.Printf("Node %s initialized", s.n.Id())

	return s.n.Reply(msg, map[string]any{
		"type": "init_ok",
	})
}

func (s *Server) echoHandler(msg m.Message) error {
	var body m.EchoMessageBody
	if err := json.Unmarshal(msg.Body, &body); err != nil {
		return fmt.Errorf("unmarshal init message body: %w", err)
	}

	return s.n.Reply(msg, map[string]any{
		"type": "echo_ok",
		"echo": body.Echo,
	})
}

func main() {
	n := m.NewNode()
	s := &Server{n: n}

	n.Handle("init", s.initHandler)
	n.Handle("echo", s.echoHandler)

	if err := n.Run(); err != nil {
		log.Fatal(err)
	}
}
