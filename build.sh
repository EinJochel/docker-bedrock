#!/bin/zsh

set -e

if [[ -f ./.env ]]; then
	source ./.env
fi

if [[ $1 == (--version|-v) && -n $2 ]]; then
	VERSION=$2
fi

if [[ -z $VERSION ]]; then
	echo "Usage: ./build.sh --version <version>"
	exit 1
fi

docker build \
	--tag bedrock \
	--tag bedrock:$VERSION \
	--platform linux/amd64 \
	--build-arg version=$VERSION \
	.
