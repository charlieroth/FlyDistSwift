package maelstrom

import (
	"bufio"
	"context"
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

func (m *Message) RPCError() *RPCError {
	var body MessageBody
	if err := json.Unmarshal(m.Body, &body); err != nil {
		return NewRPCError(Crash, err.Error())
	} else if body.Code == 0 {
		return nil
	}

	return NewRPCError(body.Code, body.Text)
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

type TopologyMessageBody struct {
	MessageBody
	Topology  map[string][]string   `json:"topology,omitempty"`
}

type BroadcastMessageBody struct {
	MessageBody
	Message  int   `json:"message,omitempty"`
}

type ReadMessageBody struct {
	MessageBody
	Messages []int `json:"messages,omitempty"`
}

type HandlerFunc func(msg Message) error

type Node struct {
	mu sync.Mutex
	wg sync.WaitGroup

	id        string
	nodeIds   []string
	nextMsgId int

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

		if body.InReplyTo != 0 {
			// extract callback, if replying to a previous message
			n.mu.Lock()
			h := n.callbacks[body.InReplyTo]
			delete(n.callbacks, body.InReplyTo)
			n.mu.Unlock()

			if h == nil {
				log.Printf("Ingoring reply to %d with no callback", body.InReplyTo)
				continue
			}

			n.wg.Add(1)
			go func() {
				defer n.wg.Done()
				n.handleCallback(h, msg)
			}()
			continue
		}

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

func (n *Node) handleCallback(h HandlerFunc, msg Message) {
	if err := h(msg); err != nil {
		log.Printf("callback error: %s", err)
	}
}

func (n *Node) handleMessage(h HandlerFunc, msg Message) {
	if err := h(msg); err != nil {
		switch err := err.(type) {
		case *RPCError:
			if err := n.Reply(msg, err); err != nil {
				log.Printf("reply error: %s", err)
			}
		default:
			log.Printf("Exception handling %#v:\n%s", msg, err)
			if err := n.Reply(msg, NewRPCError(Crash, err.Error())); err != nil {
				log.Printf("reply error: %s", err)
			}
		}
	}
}

func (n *Node) Reply(msg Message, body any) error {
	var msgBody MessageBody
	if err := json.Unmarshal(msg.Body, &msgBody); err != nil {
		return err
	}

	// marshal/unmarshal to inject reply message id
	b := make(map[string]any)
	if buf, err := json.Marshal(body); err != nil {
		return err
	} else if err := json.Unmarshal(buf, &b); err != nil {
		return err
	}
	b["in_reply_to"] = msgBody.MsgId
	return n.Send(msg.Src, b)
}

func (n *Node) SyncRPC(ctx context.Context, dest string, body any) (Message, error) {
	responseChan := make(chan Message)
	if err := n.RPC(dest, body, func (m Message) error {
		responseChan <- m
		return nil
	}); err != nil {
		return Message{}, err
	}

	select {
	case <-ctx.Done():
		return Message{}, ctx.Err()

	case m := <-responseChan:
		if err := m.RPCError(); err != nil {
			return m, err
		}

		return m, nil
	}
}

func (n *Node) RPC(dest string, body any, handler HandlerFunc) error {
	n.mu.Lock()
	n.nextMsgId++
	msgId := n.nextMsgId
	n.callbacks[msgId] = handler
	n.mu.Unlock()
	b := make(map[string]any)
	if buf, err := json.Marshal(body); err != nil {
		return err
	} else if err := json.Unmarshal(buf, &b); err != nil {
		return err
	}
	b["msg_id"] = msgId
	return n.Send(dest, b)
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

