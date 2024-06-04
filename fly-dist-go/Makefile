echo:
	cd cmd/echo && \
	go build -o echo && \
	cd - && \
	mv cmd/echo/echo bin

clean-echo:
	rm bin/echo

unique-ids:
	cd cmd/unique-ids && \
	go build -o unique-ids && \
	cd - && \
	mv cmd/unique-ids/unique-ids bin

clean-unique-ids:
	rm bin/unique-id

single-node-broadcast:
	cd cmd/single-node-broadcast && \
	go build -o single-node-broadcast && \
	cd - && \
	mv cmd/single-node-broadcast/single-node-broadcast bin

clean-single-node-broadcast:
	rm bin/single-node-broadcast

multi-node-broadcast:
	cd cmd/multi-node-broadcast && \
	go build -o multi-node-broadcast && \
	cd - && \
	mv cmd/multi-node-broadcast/multi-node-broadcast bin

clean-multi-node-broadcast:
	rm bin/multi-node-broadcast