# Use latest amd64 Ubuntu
FROM ubuntu:latest

# The Minecraft Bedrock Server version
ARG version

# Metadata
LABEL org.opencontainers.image.title="Minecraft Bedrock Server"
LABEL org.opencontainers.image.description="A Minecraft Bedrock Server running on Ubuntu"
LABEL org.opencontainers.image.ref.name=bedrock
LABEL org.opencontainers.image.version=$version

# Disables interactive prompts from Ubuntu
ENV DEBIAN_FRONTEND="noninteractive"

# Needed by the Minecraft Bedrock Server
ENV LD_LIBRARY_PATH="/usr/local/share/bedrock"

# Install updates and dependencies
RUN apt update && \
    apt upgrade -y && \
    apt install -y --no-install-recommends \
        ca-certificates \
        libcurl4 \
        unzip \
        netcat-openbsd && \
    apt auto-remove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
RUN mkdir -p /usr/local/share/bedrock
WORKDIR /usr/local/share/bedrock

# Minecraft Bedrock Server files (https://www.minecraft.net/de-de/download/server/bedrock)
ADD https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-$version.zip bedrock.zip
RUN unzip bedrock.zip && \
    rm bedrock.zip && \
    mv bedrock_server /usr/local/bin/bedrock && \
    mkdir -p default-config && \
    mv allowlist.json permissions.json server.properties default-config && \
    mkdir -p /bedrock/worlds && \
    cp -R default-config/* /bedrock && \
    ln -s /bedrock/* .
VOLUME /bedrock

# Ports
EXPOSE 19132/tcp 19132/udp
EXPOSE 19133/tcp 19133/udp

# Entrypoint script
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh && \
    mv entrypoint.sh /usr/local/bin/entrypoint
ENTRYPOINT ["entrypoint"]

# Health check
HEALTHCHECK --interval=10s --timeout=1s --start-period=10s --retries=3 \
    CMD nc -u -z -w 0 $(hostname --ip-address) 19132 || exit 1
