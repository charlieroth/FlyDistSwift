package main

import (
	"encoding/json"
	"fmt"
	"log"
	"sync"

	m "github.com/charlieroth/gossip-gloomers/fly-dist-go/maelstrom"
)

type Server struct {
	n *m.Node
	messagesMu sync.RWMutex
	messages  map[int]int8
}

func (s *Server) allMessages() []int {
	s.messagesMu.RLock()
	messages := make([]int, 0, len(s.messages))
	for message := range s.messages {
		messages = append(messages, message)
	}
	s.messagesMu.RUnlock()

	return messages
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

func (s *Server) topologyHandler(msg m.Message) error {
	var body m.TopologyMessageBody
	if err := json.Unmarshal(msg.Body, &body); err != nil {
		return fmt.Errorf("unmarshal init message body: %w", err)
	}

	return s.n.Reply(msg, map[string]any{
		"type": "topology_ok",
	})
}

func (s *Server) broadcastHandler(msg m.Message) error {
	var body m.BroadcastMessageBody
	if err := json.Unmarshal(msg.Body, &body); err != nil {
		return fmt.Errorf("unmarshal init message body: %w", err)
	}
	
	s.messagesMu.Lock()
	if _, exists := s.messages[body.Message]; exists {
		s.messagesMu.Unlock()
		return nil
	}
	s.messages[body.Message] = 1
	s.messagesMu.Unlock()

	return s.n.Reply(msg, map[string]any{
		"type": "broadcast_ok",
	})
}

func (s *Server) readHandler(msg m.Message) error {
	var body m.MessageBody
	if err := json.Unmarshal(msg.Body, &body); err != nil {
		return fmt.Errorf("unmarshal init message body: %w", err)
	}

	messages := s.allMessages()

	return s.n.Reply(msg, map[string]any{
		"type": "read_ok",
		"messages": messages,
	})
}

func main() {
	n := m.NewNode()
	s := &Server{n: n, messages: make(map[int]int8)}

	n.Handle("init", s.initHandler)
	n.Handle("topology", s.topologyHandler)
	n.Handle("broadcast", s.broadcastHandler)
	n.Handle("read", s.readHandler)

	if err := n.Run(); err != nil {
		log.Fatal(err)
	}
}


