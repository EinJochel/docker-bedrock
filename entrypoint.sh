#!/bin/bash

# Fail fast
set -e

# Check if running in Docker container
if [[ \
	$(uname -s) != "Linux" || \
	! -x $(command -v bedrock) || \
	! -d /bedrock || \
	! -d /usr/local/share/bedrock/default-config \
]]; then
	echo "This script should not be run outside the container."
	exit 1
fi

# Copy default configs, if they are missing
if [ ! -f /bedrock/allowlist.json ]; then
	cp /usr/local/share/bedrock/default-config/allowlist.json /bedrock
fi
if [ ! -f /bedrock/permissions.json ]; then
	cp /usr/local/share/bedrock/default-config/permissions.json /bedrock
fi
if [ ! -f /bedrock/server.properties ]; then
	cp /usr/local/share/bedrock/default-config/server.properties /bedrock
fi
if [ ! -d /bedrock/worlds ]; then
	mkdir -p /bedrock/worlds
fi

# Use a FIFO so container stdin can be forwarded to bedrock
FIFO="/tmp/bedrock.stdin.fifo"
if [ ! -p "$FIFO" ]; then
	rm -f "$FIFO" || true
	mkfifo "$FIFO"
	chmod 600 "$FIFO"
fi

gracefulShutdown() {
	# Send "stop" command to bedrock's stdin
	if [ -p "$FIFO" ]; then
		printf "stop\n" > "$FIFO" 2>/dev/null || true
	else
		printf "stop\n" > /dev/console 2>/dev/null || true
	fi

	# Wait up to 30s for bedrock to exit
	waitSeconds=0
	while [ $waitSeconds -lt 30 ]; do
		if ! kill -0 "$BEDROCK_PID" 2>/dev/null; then
			break
		fi
		sleep 1
		waitSeconds=$((waitSeconds + 1))
	done

	if kill -0 "$BEDROCK_PID" 2>/dev/null; then
		# Process did not stop in time. Killing ...
		kill -9 "$BEDROCK_PID" 2>/dev/null || true
	fi
}

trap gracefulShutdown SIGTERM SIGINT SIGQUIT

# Start a background forwarder that copies container stdin into the FIFO.
# This allows interactive attach: Whatever you type is forwarded to bedrock.
cat <&0 > "$FIFO" &
FORWARDER_PID=$!

# Start bedrock with its stdin coming from the FIFO.
bedrock "$@" < "$FIFO" &
BEDROCK_PID=$!

# When bedrock exits, kill the forwarder and remove the FIFO.
wait $BEDROCK_PID
EXIT_STATUS=$?

if kill -0 "$FORWARDER_PID" 2>/dev/null; then
	kill "$FORWARDER_PID" 2>/dev/null || true
fi

rm -f "$FIFO" || true
exit $EXIT_STATUS
