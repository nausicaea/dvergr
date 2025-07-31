# syntax=docker/dockerfile:1

FROM docker.io/library/rust:1.88.0-alpine3.20 as tools
ARG OPENSSL_STATIC=1
ARG OPENSSL_LIB_DIR=/usr/lib
ARG OPENSSL_INCLUDE_DIR=/usr/include
WORKDIR /src
COPY --link modrinth /src
RUN apk add --no-cache openssl-libs-static openssl-dev musl-dev
RUN --mount=type=cache,target=/src/target/release/build --mount=type=cache,target=/src/target/release/deps cargo build --locked --release

FROM docker.io/library/alpine:3.20.3 AS downloader
ARG MINECRAFT_VERSION
ARG FABRIC_LOADER_VERSION
ARG FABRIC_LOADER_CHECKSUM
ARG FABRIC_INSTALLER_VERSION
ARG OTEL_JAVAAGENT_VERSION
ARG OTEL_JAVAAGENT_CHECKSUM
RUN apk add --no-cache curl jq python3
ADD --link --checksum=${FABRIC_LOADER_CHECKSUM} https://meta.fabricmc.net/v2/versions/loader/${MINECRAFT_VERSION}/${FABRIC_LOADER_VERSION}/${FABRIC_INSTALLER_VERSION}/server/jar /artefacts/lib/fabric-launcher.jar
ADD --link --checksum=${OTEL_JAVAAGENT_CHECKSUM} https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_JAVAAGENT_VERSION}/opentelemetry-javaagent.jar /artefacts/lib/opentelemetry-javaagent.jar
COPY --link --from=tools --chmod=0755 /src/target/release/modrinth /bin/modrinth
RUN --mount=type=bind,target=/tmp/Modrinth.toml,source=./Modrinth.toml --mount=type=bind,target=/tmp/Modrinth.lock,source=./Modrinth.lock <<-EOC
set -xe;
mkdir -p /artefacts;
export RUST_LOG="modrinth=debug";
/bin/modrinth -o /artefacts -s --lockfile /tmp/Modrinth.lock --manifest /tmp/Modrinth.toml;
EOC

FROM docker.io/library/gradle:8.10.1-jdk21-alpine AS builder
ARG MINECRAFT_VERSION
ARG YARN_MAPPINGS_VERSION
ARG FABRIC_LOADER_VERSION
WORKDIR /src
COPY --link otel-mod /src
RUN --mount=type=cache,target=/src/.gradle gradle --no-daemon :assemble

FROM docker.io/library/eclipse-temurin:21.0.4_7-jre-alpine
ARG MINECRAFT_VERSION
ENV MINECRAFT_SERVER_ID=minecraft
ENV JAVA_INITIAL_MEM=256M
ENV JAVA_MAX_MEM=2G
ENV OTEL_EXPORTER_OTLP_ENDPOINT=""

RUN <<-EOC
set -xe;
addgroup -S -g 10001 minecraft;
adduser -S -u 10001 -G minecraft -h /var/lib/minecraft -g "Minecraft Server" -s /bin/sh minecraft;
EOC
COPY --link --chmod=0755 docker-entrypoint.sh /bin/docker-entrypoint
COPY --link --chmod=0755 healthcheck.sh /bin/healthcheck
COPY --link --from=downloader --chmod=0644 /artefacts/lib/*.jar /usr/local/lib/
WORKDIR /var/lib/minecraft
COPY --link --chown=10001:10001 player-config/ ./player-config/
COPY --link --chown=10001:10001 mod-config/ ./config/
COPY --link --chown=10001:10001 --chmod=0400 server-icon.png ./
COPY --link --chown=10001:10001 --chmod=0400 eula.txt server.properties log4j2.xml opentelemetry.properties ./server-config/
COPY --link --from=builder --chown=10001:10001 --chmod=0400 /src/build/libs/otel-0.0.0.jar ./mods/
COPY --link --from=downloader --chown=10001:10001 --chmod=0400 /artefacts/fabric/*.jar ./mods/
COPY --link --from=downloader --chown=10001:10001 --chmod=0400 /artefacts/datapack/*.zip ./universe/world/datapacks/
RUN <<-EOC
set -xe;
ln -s ./server-config/eula.txt eula.txt;
ln -s ./server-config/server.properties server.properties;
ln -s ./player-config/whitelist.json whitelist.json;
ln -s ./player-config/ops.json ops.json;
ln -s ./player-config/banned-ips.json banned-ips.json;
ln -s ./player-config/banned-players.json banned-players.json;
mkdir -p .cache .fabric backups crash-reports libraries logs mods/luckperms polymer stackdeobf_mappings universe versions;
chown -R 10001:10001 /var/lib/minecraft;
find . -type d -exec chmod 0700 {} \+;
find . -type f -exec chmod 0600 {} \+;
EOC

EXPOSE 30000/tcp 30000/udp 30001/udp
USER minecraft:minecraft
ENTRYPOINT ["/bin/docker-entrypoint"]
