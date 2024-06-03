package maelstrom

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"sync"
)

type Message struct {
	Src  string          `json:"src,omitempty"`
	Dest string          `json:"dest,omitempty"`
	Body json.RawMessage `json:"body,omitempty"`
}

func (m *Message) Type() string {
	var body MessageBody
	if err := json.Unmarshal(m.Body, &body); err != nil {
		return ""
	}
	return body.Type
}

type MessageBody struct {
	Type      string `json:"type,omitempty"`
	MsgId     int    `json:"msg_id,omitempty"`
	InReplyTo int    `json:"in_reply_to,omitempty"`
	Code      int    `json:"code,omitempty"`
	Text      string `json:"text,omitempty"`
}

type InitMessageBody struct {
	MessageBody
	NodeId  string   `json:"node_id,omitempty"`
	NodeIds []string `json:"node_ids,omitempty"`
}

type EchoMessageBody struct {
	MessageBody
	Echo  string   `json:"echo,omitempty"`
}

type GenerateMessageBody struct {
	MessageBody
	Id  int   `json:"id,omitempty"`
}

type HandlerFunc func(msg Message) error

type Node struct {
	mu sync.Mutex
	wg sync.WaitGroup

	id        string
	nodeIds   []string
	// nextMsgId int

	handlers  map[string]HandlerFunc
	callbacks map[int]HandlerFunc

	Stdin  io.Reader
	Stdout io.Writer
}

func NewNode() *Node {
	return &Node{
		handlers:  make(map[string]HandlerFunc),
		callbacks: make(map[int]HandlerFunc),
		Stdin:     os.Stdin,
		Stdout:    os.Stdout,
	}
}

func (n *Node) Init(id string, nodeIds []string) {
	n.id = id
	n.nodeIds = nodeIds
}

func (n *Node) Id() string {
	return n.id
}

func (n *Node) NodeIds() []string {
	return n.nodeIds
}

func (n *Node) Handle(handlerType string, fn HandlerFunc) {
	if _, ok := n.handlers[handlerType]; ok {
		panic(fmt.Sprintf("duplicate message handler for %q message type", handlerType))
	}
	n.handlers[handlerType] = fn
}

func (n *Node) Run() error {
	scanner := bufio.NewScanner(n.Stdin)
	for scanner.Scan() {
		line := scanner.Bytes()
		var msg Message
		if err := json.Unmarshal(line, &msg); err != nil {
			return fmt.Errorf("unmarshal message: %w", err)
		}

		var body MessageBody
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return fmt.Errorf("unmarshal message body: %w", err)
		}
		log.Printf("Receieved %s", msg)

		var h HandlerFunc
		if h = n.handlers[body.Type]; h == nil {
			return fmt.Errorf("no handler for %s", line)
		}

		// Handle message in a separate go routine
		n.wg.Add(1)
		go func() {
			defer n.wg.Done()
			n.handleMessage(h, msg)
		}()
	}

	if err := scanner.Err(); err != nil {
		return err
	}

	// Wait for all handlers to complete
	n.wg.Wait()

	return nil
}

func (n *Node) handleMessage(h HandlerFunc, msg Message) {
	if err := h(msg); err != nil {
		log.Printf("Exception handle %#v:\n%s", msg, err)
	}
}

func (n *Node) Send(dest string, body any) error {
	bodyJson, err := json.Marshal(body)
	if err != nil {
		return err
	}

	buf, err := json.Marshal(Message{
		Src: n.id,
		Dest: dest,
		Body: bodyJson,
	})
	if err != nil {
		return err
	}

	// synchronize access to STDOUT
	n.mu.Lock()
	defer n.mu.Unlock()

	log.Printf("sent: %s", buf)

	if _, err = n.Stdout.Write(buf); err != nil {
		return err
	}

	_, err = n.Stdout.Write([]byte{'\n'})
	return err
}
