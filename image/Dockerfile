FROM docker.io/library/eclipse-temurin:21-jre-alpine@sha256:3f716d52e4045433e94a28d029c93d3c23179822a5d40b1c82b63aedd67c5081
VOLUME ["/var/lib/minecraft/.cache", "/var/lib/minecraft/audioplayer_uploads", "/var/lib/minecraft/backups", "/var/lib/minecraft/config", "/var/lib/minecraft/logs", "/var/lib/minecraft/players", "/var/lib/minecraft/server", "/var/lib/minecraft/universe"]
EXPOSE 25565/tcp 24454/udp
ARG MINECRAFT_VERSION=1.21.1
ARG MINECRAFT_SERVER_ID=minecraft
ENV MINECRAFT_SERVER_ID=${MINECRAFT_SERVER_ID}
ENV JAVA_INITIAL_MEM=256m
ENV JAVA_MAX_MEM=2g

ADD --checksum=sha256:c3ad3e23eee860e5185c594e7cb280e4fabe7e766a83945381d9a99c64855c5b https://quiltmc.org/api/v1/download-latest-installer/java-universal /tmp/quilt-installer.jar
ADD --checksum=sha256:306058903db26cedaf9ea60eb210edf3e7b52524f13724d5874f1d0622323e65 https://github.com/getsentry/sentry-java/releases/download/7.14.0/sentry-opentelemetry-agent-7.14.0.zip /tmp/sentry-opentelemetry-agent-7.14.0.zip
RUN set -xe; \
    addgroup -S minecraft; \
    adduser -S -G minecraft -h /var/lib/minecraft -g "Minecraft Server" -s /bin/sh minecraft; \
    java -jar /tmp/quilt-installer.jar install server ${MINECRAFT_VERSION} --download-server --install-dir=/usr/local/lib/minecraft; \
    rm /tmp/quilt-installer.jar; \
    unzip /tmp/sentry-opentelemetry-agent-7.14.0.zip -d /usr/local/lib/; \
    ln -s /usr/local/lib/sentry-opentelemetry-agent-7.14.0/sentry-opentelemetry-agent-7.14.0.jar /usr/local/lib/sentry-opentelemetry-agent.jar; \
    rm /tmp/sentry-opentelemetry-agent-7.14.0.zip

WORKDIR /var/lib/minecraft
COPY quilt-server-launcher.properties eula.txt ./
COPY mods mods
COPY config config
WORKDIR /var/lib/minecraft/server
COPY log4j2.xml server.properties sentry.properties ./
WORKDIR /var/lib/minecraft/players
COPY ops.json whitelist.json banned-ips.json banned-players.json ./
WORKDIR /var/lib/minecraft
RUN set -xe; \
    mkdir -p .cache audioplayer_uploads backups logs universe; \
    ln -s server/server.properties server.properties; \
    ln -s players/ops.json ops.json; \
    ln -s players/whitelist.json whitelist.json; \
    ln -s players/banned-ips.json banned-ips.json; \
    ln -s players/banned-players.json banned-players.json; \
    java -jar /usr/local/lib/minecraft/quilt-server-launch.jar --initSettings; \
    chown -R minecraft:minecraft .
COPY --chmod=0755 docker-entrypoint.sh /bin/docker-entrypoint

USER minecraft:minecraft
ENTRYPOINT ["/bin/docker-entrypoint"]
