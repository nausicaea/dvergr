# syntax=docker/dockerfile:1

FROM docker.io/library/alpine:3.20.3 AS downloader
ARG MODRINTH_PAT
ARG MINECRAFT_VERSION
ARG FABRIC_LOADER_VERSION
ARG FABRIC_LOADER_CHECKSUM
ARG FABRIC_INSTALLER_VERSION
ARG OTEL_JAVAAGENT_VERSION
ARG OTEL_JAVAAGENT_CHECKSUM
RUN apk add curl jq python3
ADD --link --checksum=${FABRIC_LOADER_CHECKSUM} https://meta.fabricmc.net/v2/versions/loader/${MINECRAFT_VERSION}/${FABRIC_LOADER_VERSION}/${FABRIC_INSTALLER_VERSION}/server/jar /artefacts/lib/fabric-launcher.jar
ADD --link --checksum=${OTEL_JAVAAGENT_CHECKSUM} https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_JAVAAGENT_VERSION}/opentelemetry-javaagent.jar /artefacts/lib/opentelemetry-javaagent.jar
COPY --link --chmod=0755 modrinth.py /bin/modrinth
RUN mkdir -p /artefacts/mods /artefacts/datapacks
RUN --mount=type=bind,target=/tmp/mods.txt,source=./mods.txt /bin/modrinth -d -O /artefacts/mods -l fabric -i /tmp/mods.txt
RUN --mount=type=bind,target=/tmp/datapacks.txt,source=./datapacks.txt /bin/modrinth -d -O /artefacts/datapacks -l datapack -i /tmp/datapacks.txt

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
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

RUN set -xe; \
    addgroup -S -g 10001 minecraft; \
    adduser -S -u 10001 -G minecraft -h /var/lib/minecraft -g "Minecraft Server" -s /bin/sh minecraft
COPY --link --chmod=0755 docker-entrypoint.sh /bin/docker-entrypoint
COPY --link --from=downloader --chmod=0644 /artefacts/lib/*.jar /usr/local/lib/
WORKDIR /var/lib/minecraft
COPY --link --chown=10001:10001 player-config/ ./player-config/
COPY --link --chown=10001:10001 mod-config/ ./config/
COPY --link --chown=10001:10001 --chmod=0400 server-icon.png ./
COPY --link --chown=10001:10001 --chmod=0400 eula.txt server.properties log4j2.xml opentelemetry.properties ./server-config/
COPY --link --from=builder --chown=10001:10001 --chmod=0400 /src/build/libs/otel-0.0.0.jar ./mods/
COPY --link --from=downloader --chown=10001:10001 --chmod=0400 /artefacts/mods/*.jar ./mods/
COPY --link --from=downloader --chown=10001:10001 --chmod=0400 /artefacts/datapacks/*.zip ./config/paxi/datapacks/
RUN <<-EOC
    set -xe;
    ln -s ./server-config/eula.txt eula.txt;
    ln -s ./server-config/server.properties server.properties;
    ln -s ./player-config/whitelist.json whitelist.json;
    ln -s ./player-config/ops.json ops.json;
    ln -s ./player-config/banned-ips.json banned-ips.json;
    ln -s ./player-config/banned-players.json banned-players.json;
    mkdir -p .cache .fabric backups crash-reports libraries logs mods/luckperms polymer stackdeobf_mappings universe versions;
    chown 10001:10001 .cache .fabric backups crash-reports libraries logs mods/luckperms polymer stackdeobf_mappings universe versions;
EOC

EXPOSE 30000/tcp 30000/udp 30001/udp
USER minecraft:minecraft
ENTRYPOINT ["/bin/docker-entrypoint"]
