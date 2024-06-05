# Gossip Glomers

Solving Fly's _Gossip Glomers_ distributed systems challenges in what I believe are the best
languages for building concurrent, distributed systems.

## Maelstrom Commands

### Challenge 1: Echo

```bash
./maelstrom test -w echo --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/echo --node-count 1 --time-limit 10
```

### Challenge 2: Unique ID Generation

```bash
./maelstrom test -w unique-ids --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/echo --time-limit 30 --rate 1000 --node-count 3 --availability total --nemesis partition
```

### Challenge 3a: Single-Node Broadcast

```bash
./maelstrom test -w broadcast --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/single-node-broadcast --node-count 1 --time-limit 20 --rate 10
```

### Challenge 3b: Multi-Node Broadcast

```bash
./maelstrom test -w broadcast --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/multi-node-broadcast --node-count 5 --time-limit 20 --rate 10
```

### Challenge 3c: Fault-Tolerant Broadcast

```bash
./maelstrom test -w broadcast --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/fault-tolerant-broadcast --node-count 5 --time-limit 20 --rate 10 --nemesis partition
```

### Challenge 3d: Efficient Broadcast, Part I

```bash
./maelstrom test -w broadcast --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/efficient-broadcast-one --node-count 25 --time-limit 20 --rate 100 --latency 100
```

### Challenge 3e: Efficient Broadcast, Part II

```bash
./maelstrom test -w broadcast --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/efficient-broadcast-two --node-count 25 --time-limit 20 --rate 100 --latency 100
```

### Challenge 4: Grow-Only Counter

```bash
./maelstrom test -w g-counter --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/gcounter --node-count 3 --rate 100 --time-limit 20 --nemesis partition
```

### Challenge 5a: Single-Node Kafka-Style Log

```bash
./maelstrom test -w kafka --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/single-node-kafka --node-count 1 --concurrency 2n --time-limit 20 --rate 1000
```

### Challenge 5b: Multi-Node Kafka-Style Log

```bash
./maelstrom test -w kafka --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/multi-node-kafka --node-count 2 --concurrency 2n --time-limit 20 --rate 1000
```

### Challenge 5c: Efficient Kafka-Style Log

```bash
./maelstrom test -w kafka --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/efficient-kafka --node-count 2 --concurrency 2n --time-limit 20 --rate 1000
```

### Challenge 6a: Single-Node, Totally-Available Transactions

```bash
./maelstrom test -w txn-rw-register --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/single-node-txn --node-count 1 --time-limit 20 --rate 1000 --concurrency 2n --consistency-models read-uncommitted --availability total
```

### Challenge 6b: Totally-Available, Read Uncommited Transactions

```bash
./maelstrom test -w txn-rw-register --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/read-uncommitted-txn --node-count 2 --concurrency 2n --time-limit 20 --rate 1000 --consistency-models read-uncommitted

./maelstrom test -w txn-rw-register --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/read-uncommitted-txn --node-count 2 --concurrency 2n --time-limit 20 --rate 1000 --consistency-models read-uncommitted --availability total --nemesis partition
```

### Challenge 6c: Totally-Available, Read Commited Transactions

```bash
./maelstrom test -w txn-rw-register --bin ~/github.com/charlieroth/gossip-glomers/fly-dist-go/bin/read-committed-txn --node-count 2 --concurrency 2n --time-limit 20 --rate 1000 --consistency-models read-committed --availability total –-nemesis partition
```

### Language-Challenge-Breakdown

#### Swift

- [x] Challenge 1: Echo
- [x] Challenge 2: Unique ID Generation
- [x] Challenge 3a: Single-Node Broadcast
- [x] Challenge 3b: Multi-Node Broadcast
- [ ] Challenge 3c: Fault Tolerant Broadcast
- [ ] Challenge 3d: Efficient Broadcast, Part 1
- [ ] Challenge 3e: Efficient Broadcast, Part 2
- [ ] Challenge 4: Grow-Only Counter
- [ ] Challenge 5a: Single-Node Kafka-Style Log
- [ ] Challenge 5b: Multi-Node Kafka-Style Log
- [ ] Challenge 5c: Efficient Kafka-Style Log
- [ ] Challenge 6a: Single-Node, Totally Available Transactions
- [ ] Challenge 6b: Totally-Available, Read Uncommitted Transactions
- [ ] Challenge 6c: Totally-Available, Read Committed Transactions

#### Go

- [x] Challenge 1: Echo
- [x] Challenge 2: Unique ID Generation
- [x] Challenge 3a: Single-Node Broadcast
- [x] Challenge 3b: Multi-Node Broadcast
- [x] Challenge 3c: Fault Tolerant Broadcast
- [ ] Challenge 3d: Efficient Broadcast, Part 1
- [ ] Challenge 3e: Efficient Broadcast, Part 2
- [ ] Challenge 4: Grow-Only Counter
- [ ] Challenge 5a: Single-Node Kafka-Style Log
- [ ] Challenge 5b: Multi-Node Kafka-Style Log
- [ ] Challenge 5c: Efficient Kafka-Style Log
- [ ] Challenge 6a: Single-Node, Totally Available Transactions
- [ ] Challenge 6b: Totally-Available, Read Uncommitted Transactions
- [ ] Challenge 6c: Totally-Available, Read Committed Transactions

#### Elixir

- [ ] Challenge 1: Echo
- [ ] Challenge 2: Unique ID Generation
- [ ] Challenge 3a: Single-Node Broadcast
- [ ] Challenge 3b: Multi-Node Broadcast
- [ ] Challenge 3c: Fault Tolerant Broadcast
- [ ] Challenge 3d: Efficient Broadcast, Part 1
- [ ] Challenge 3e: Efficient Broadcast, Part 2
- [ ] Challenge 4: Grow-Only Counter
- [ ] Challenge 5a: Single-Node Kafka-Style Log
- [ ] Challenge 5b: Multi-Node Kafka-Style Log
- [ ] Challenge 5c: Efficient Kafka-Style Log
- [ ] Challenge 6a: Single-Node, Totally Available Transactions
- [ ] Challenge 6b: Totally-Available, Read Uncommitted Transactions
- [ ] Challenge 6c: Totally-Available, Read Committed Transactions
