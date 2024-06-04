package internal

import "sync"

type Store struct {
	mu       sync.Mutex
	messages map[float64]bool
}

func NewStore() *Store {
	return &Store{messages: make(map[float64]bool)}
}

func (s *Store) Add(key float64) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.messages[key]; ok {
		return false
	} else {
		s.messages[key] = true
		return true
	}
}

func (s *Store) ReadAll() []float64 {
	s.mu.Lock()
	defer s.mu.Unlock()
	var messages []float64
	for message := range s.messages {
		messages = append(messages, message)
	}
	return messages
}
