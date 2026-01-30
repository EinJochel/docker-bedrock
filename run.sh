#!/bin/zsh

set -e

docker run \
	--name bedrock \
	--platform linux/amd64 \
	--tty \
	--interactive \
	--hostname bedrock \
	--publish 19132:19132/tcp \
	--publish 19132:19132/udp \
	--publish 19133:19133/tcp \
	--publish 19133:19133/udp \
	--volume bedrock:/bedrock \
	bedrock
