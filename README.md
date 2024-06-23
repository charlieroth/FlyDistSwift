# Gossip Glomers

Solving Fly's _Gossip Glomers_ distributed systems challenges with Swift

## Challenge Checklist

- [x] Challenge 1: Echo
- [x] Challenge 2: Unique ID Generation
- [x] Challenge 3a: Single-Node Broadcast
- [x] Challenge 3b: Multi-Node Broadcast
- [x] Challenge 3c: Fault Tolerant Broadcast
- [x] Challenge 3d: Efficient Broadcast, Part 1
- [x] Challenge 3e: Efficient Broadcast, Part 2
- [x] Challenge 4: Grow-Only Counter
- [x] Challenge 5a: Single-Node Kafka-Style Log
- [x] Challenge 5b: Multi-Node Kafka-Style Log
- [x] Challenge 5c: Efficient Kafka-Style Log (See `MultiNodeKafka/`
  solution)
- [ ] Challenge 6a: Single-Node, Totally Available Transactions
- [ ] Challenge 6b: Totally-Available, Read Uncommitted Transactions
- [ ] Challenge 6c: Totally-Available, Read Committed Transactions

## Maelstrom Commands

### Challenge 1: Echo

```bash
./maelstrom test -w echo --bin ~/path/to/bin --node-count 1 --time-limit 10
```

### Challenge 2: Unique ID Generation

```bash
./maelstrom test -w unique-ids --bin ~/path/to/bin --time-limit 30 --rate 1000 --node-count 3 --availability total --nemesis partition
```

### Challenge 3a: Single-Node Broadcast

```bash
./maelstrom test -w broadcast --bin ~/path/to/bin --node-count 1 --time-limit 20 --rate 10
```

### Challenge 3b: Multi-Node Broadcast

```bash
./maelstrom test -w broadcast --bin ~/path/to/bin --node-count 5 --time-limit 20 --rate 10
```

### Challenge 3c: Fault-Tolerant Broadcast

```bash
./maelstrom test -w broadcast --bin ~/path/to/bin --node-count 5 --time-limit 20 --rate 10 --nemesis partition
```

### Challenge 3d: Efficient Broadcast, Part I

```bash
./maelstrom test -w broadcast --bin ~/path/to/bin --node-count 25 --time-limit 20 --rate 100 --latency 100
```

### Challenge 3e: Efficient Broadcast, Part II

```bash
./maelstrom test -w broadcast --bin ~/path/to/bin --node-count 25 --time-limit 20 --rate 100 --latency 100
```

### Challenge 4: Grow-Only Counter

```bash
./maelstrom test -w g-counter --bin ~/path/to/bin --node-count 3 --rate 100 --time-limit 20 --nemesis partition
```

### Challenge 5a: Single-Node Kafka-Style Log

```bash
./maelstrom test -w kafka --bin ~/path/to/bin --node-count 1 --concurrency 2n --time-limit 20 --rate 1000
```

### Challenge 5b: Multi-Node Kafka-Style Log

```bash
./maelstrom test -w kafka --bin ~/path/to/bin --node-count 2 --concurrency 2n --time-limit 20 --rate 1000
```

### Challenge 5c: Efficient Kafka-Style Log

```bash
./maelstrom test -w kafka --bin ~/path/to/bin --node-count 2 --concurrency 2n --time-limit 20 --rate 1000
```

### Challenge 6a: Single-Node, Totally-Available Transactions

```bash
./maelstrom test -w txn-rw-register --bin ~/path/to/bin --node-count 1 --time-limit 20 --rate 1000 --concurrency 2n --consistency-models read-uncommitted --availability total
```

### Challenge 6b: Totally-Available, Read Uncommited Transactions

```bash
./maelstrom test -w txn-rw-register --bin ~/path/to/bin --node-count 2 --concurrency 2n --time-limit 20 --rate 1000 --consistency-models read-uncommitted

./maelstrom test -w txn-rw-register --bin ~/path/to/bin --node-count 2 --concurrency 2n --time-limit 20 --rate 1000 --consistency-models read-uncommitted --availability total --nemesis partition
```

### Challenge 6c: Totally-Available, Read Commited Transactions

```bash
./maelstrom test -w txn-rw-register --bin ~/path/to/bin --node-count 2 --concurrency 2n --time-limit 20 --rate 1000 --consistency-models read-committed --availability total –-nemesis partition
```

