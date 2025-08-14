# syntax=docker/dockerfile:1

### Builds the final Java runtime image
FROM docker.io/library/eclipse-temurin:21.0.7_6-jdk-alpine-3.21 AS builder_c
RUN apk add --no-cache binutils
# Build small JRE image
WORKDIR /artefacts
RUN $JAVA_HOME/bin/jlink \
         --verbose \
         #--add-modules ALL-MODULE-PATH \
         --add-modules java.base,java.desktop,java.instrument,java.management,java.net.http,java.sql,jdk.jfr,jdk.unsupported,jdk.zipfs,jdk.crypto.ec,java.compiler,jdk.httpserver,java.naming \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress zip-9 \
         --output /artefacts/optimized-jdk-21

### Downloads all selected mods and datapacks from Modrinth
FROM ghcr.io/nausicaea/nema:v0.3.0 AS downloader
ARG MINECRAFT_VERSION
ARG FABRIC_LOADER_VERSION
ARG FABRIC_LOADER_CHECKSUM
ARG FABRIC_INSTALLER_VERSION
ARG OTEL_JAVAAGENT_VERSION
ARG OTEL_JAVAAGENT_CHECKSUM
ARG JOLOKIA_JAVAAGENT_VERSION
ARG JOLOKIA_JAVAAGENT_CHECKSUM
ARG OTEL_MOD_VERSION
ARG OTEL_MOD_CHECKSUM
ADD --link --checksum=${FABRIC_LOADER_CHECKSUM} https://meta.fabricmc.net/v2/versions/loader/${MINECRAFT_VERSION}/${FABRIC_LOADER_VERSION}/${FABRIC_INSTALLER_VERSION}/server/jar /artefacts/lib/fabric-launcher.jar
ADD --link --checksum=${OTEL_JAVAAGENT_CHECKSUM} https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_JAVAAGENT_VERSION}/opentelemetry-javaagent.jar /artefacts/lib/opentelemetry-javaagent.jar
ADD --link --checksum=${JOLOKIA_JAVAAGENT_CHECKSUM} https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-agent-jvm/${JOLOKIA_JAVAAGENT_VERSION}/jolokia-agent-jvm-${JOLOKIA_JAVAAGENT_VERSION}-javaagent.jar /artefacts/lib/jolokia-javaagent.jar
ADD --link --checksum=${OTEL_MOD_CHECKSUM} https://github.com/nausicaea/opentelemetry-fabric/releases/download/v${OTEL_MOD_VERSION}/otel-${OTEL_MOD_VERSION}.jar /artefacts/fabric/otel-${OTEL_MOD_VERSION}.jar
RUN --mount=type=secret,id=MODRINTH_PAT,env=MODRINTH_PAT --mount=type=bind,target=/tmp/Modrinth.toml,source=./Modrinth.toml --mount=type=bind,target=/tmp/Modrinth.lock,source=./Modrinth.lock <<-EOC
set -xe;
/usr/local/bin/nema -o /artefacts --strict -s --lockfile /tmp/Modrinth.lock --manifest /tmp/Modrinth.toml;
EOC

### Builds and runs the final image
FROM docker.io/library/alpine:3.22
LABEL org.opencontainers.image.title "Dvergr"
LABEL org.opencontainers.image.description "A Minecraft server with an opinionated set of mods"
LABEL org.opencontainers.image.authors "developer@nausicaea.net"
LABEL org.opencontainers.image.source "https://github.com/nausicaea/dvergr"
LABEL org.opencontainers.image.version "0.1.0+1_21_4"
LABEL org.opencontainers.image.licenses "GPL-3.0-only"
EXPOSE 30000/tcp 30000/udp
VOLUME ["/var/lib/minecraft/persistent", "/etc/minecraft", "/var/cache/minecraft", "/var/log/minecraft"]
ARG MINECRAFT_VERSION
ENV MINECRAFT_SERVER_ID=minecraft
ENV JAVA_INITIAL_MEM=256M
ENV JAVA_MAX_MEM=2G
ENV OTEL_EXPORTER_OTLP_ENDPOINT=""
ENV JOLOKIA_BIND_ADDRESS=""
ENV MAINTENANCE_MODE=0
COPY --from=builder_c /artefacts/optimized-jdk-21 /opt/java/customjdk
RUN <<-EOC
set -xe;
addgroup -S -g 10001 minecraft;
adduser -S -u 10001 -G minecraft -h /var/lib/minecraft -g "Minecraft Server" -s /bin/sh minecraft;
EOC
COPY --link --chmod=0755 bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
COPY --link --chmod=0755 bin/healthcheck.sh /usr/local/bin/healthcheck
COPY --link --from=downloader --chmod=0644 /artefacts/lib/*.jar /usr/local/lib/

# Provision config files
WORKDIR /etc/minecraft
COPY --link --chown=10001:10001 config/ .
RUN <<-EOF
set -xe;
mkdir default;
chown -vR minecraft:minecraft .;
chmod -vR u=rwX,go=rX .;
EOF

# Provision the cache
WORKDIR /var/cache/minecraft
RUN <<-EOF
set -xe;
mkdir -v .cache .fabric .polydex cache libraries polymer stackdeobf_mappings versions;
chown -vR minecraft:minecraft .;
chmod -vR u=rwX,go=rX .;
EOF

# Provision logs
WORKDIR /var/log/minecraft
RUN <<-EOF
set -xe;
mkdir -v crash-reports;
chown -vR minecraft:minecraft .;
chmod -vR u=rwX,go=rX .;
EOF

# Provision the server home directory
WORKDIR /var/lib/minecraft
COPY --from=downloader --chown=10001:10001 /artefacts/fabric/*.jar ./mods/
COPY --from=downloader --chown=10001:10001 /artefacts/datapack/*.zip ./persistent/universe/world/datapacks/
RUN <<-EOF
set -xe;
# Create directories for volume mounts
mkdir -vp persistent/backups persistent/luckperms persistent/universe;

# Create symlinks for files and directories with hard-coded paths
# Persistent data (read-write)
ln -s /var/lib/minecraft/persistent/backups backups;
ln -s /var/lib/minecraft/persistent/luckperms mods/luckperms;
ln -s /var/lib/minecraft/persistent/universe universe;
# Configuration files (read-only)
ln -s /etc/minecraft/server/server-icon.png server-icon.png;
ln -s /etc/minecraft/server/eula.txt eula.txt;
ln -s /etc/minecraft/server/server.properties server.properties;
ln -s /etc/minecraft/player/whitelist.json whitelist.json;
ln -s /etc/minecraft/player/ops.json ops.json;
ln -s /etc/minecraft/player/banned-ips.json banned-ips.json;
ln -s /etc/minecraft/player/banned-players.json banned-players.json;
ln -s /etc/minecraft/mods config;
ln -s /etc/minecraft/default defaultconfigs;
# Caches (ephemeral)
ln -s /var/cache/minecraft/.cache ./.cache;
ln -s /var/cache/minecraft/.fabric ./.fabric;
ln -s /var/cache/minecraft/.polydex ./.polydex;
ln -s /var/cache/minecraft/cache ./cache;
ln -s /var/cache/minecraft/libraries ./libraries;
ln -s /var/cache/minecraft/polymer ./polymer;
ln -s /var/cache/minecraft/stackdeobf_mappings ./stackdeobf_mappings;
ln -s /var/cache/minecraft/versions ./versions;
# Logs (ephemeral)
ln -s /var/log/minecraft/crash-reports ./crash-reports;

# Fix ownership and permissions
chown -vR minecraft:minecraft .;
chmod -vR u=rwX,go=rX .;
EOF

USER minecraft:minecraft
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
