package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math"
	"math/rand"
	"time"

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

func (s *Server) generateHandler(msg m.Message) error {
	var body m.MessageBody
	if err := json.Unmarshal(msg.Body, &body); err != nil {
		return err
	}

	rand.New(rand.NewSource(time.Now().UnixNano()))
	randomId := rand.Intn(math.MaxInt)

	return s.n.Reply(msg, map[string]any{
		"type": "generate_ok",
		"id": randomId,
	})
}

func main() {
	n := m.NewNode()
	s := &Server{ n: n}

	n.Handle("init", s.initHandler)
	n.Handle("generate", s.generateHandler)

	if err := n.Run(); err != nil {
		log.Fatal(err)
	}
}

