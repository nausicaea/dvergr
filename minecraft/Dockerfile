# syntax=docker/dockerfile:1

FROM docker.io/library/gradle:8.10-jdk21-alpine AS builder
ARG MINECRAFT_VERSION
ARG YARN_MAPPINGS_VERSION
ARG FABRIC_LOADER_VERSION
WORKDIR /src
COPY otel-mod /src
RUN --mount=type=cache,target=/src/.gradle gradle --no-daemon :assemble

FROM docker.io/library/alpine:latest AS downloader
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
COPY --chmod=0755 modrinth.py /bin/modrinth
#ENV MODRINTH_PAT=${MODRINTH_PAT}
#ENV MINECRAFT_VERSION=${MINECRAFT_VERSION}
#ENTRYPOINT ["/bin/sh"]
RUN mkdir -p /artefacts/mods /artefacts/datapacks
RUN /bin/modrinth -d -O /artefacts/mods -l fabric \
    advanced-backups \
    afk-announcer \
    coord-finder \
    debugify \
    ferrite-core \
    just-mob-heads \
    krypton \
    leaves-us-in-peace \
    lithium \
    modernfix \
    noisium \
    sleep \
    starlight \
    vanilla-refresh \
    simple-voice-chat \
    biomes-o-plenty
RUN /bin/modrinth -d -O /artefacts/datapacks -l datapack \
    new-in-town \
    new-in-town-dimensions

FROM docker.io/library/eclipse-temurin:21-jre-alpine@sha256:3f716d52e4045433e94a28d029c93d3c23179822a5d40b1c82b63aedd67c5081
VOLUME ["/var/lib/minecraft/.fabric", "/var/lib/minecraft/config", "/var/lib/minecraft/logs", "/var/lib/minecraft/crash-reports", "/var/lib/minecraft/mods", "/var/lib/minecraft/universe"]
EXPOSE 30000/tcp 30001/udp
ARG MINECRAFT_VERSION
ENV MINECRAFT_SERVER_ID=minecraft
ENV JAVA_INITIAL_MEM=256M
ENV JAVA_MAX_MEM=2G
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

RUN set -xe; \
    addgroup -S minecraft; \
    adduser -S -G minecraft -h /var/lib/minecraft -g "Minecraft Server" -s /bin/sh minecraft
COPY --chmod=0755 docker-entrypoint.sh /bin/docker-entrypoint
COPY --from=downloader --chmod=0644 /artefacts/lib/*.jar /usr/local/lib/
USER minecraft:minecraft
WORKDIR /var/lib/minecraft
RUN java \
    -jar /usr/local/lib/fabric-launcher.jar \
    --universe /var/lib/minecraft/universe \
    --initSettings
COPY eula.txt ./
COPY --from=builder --chmod=0644 /src/build/libs/otel-0.0.0.jar ./mods/
COPY --from=downloader --chmod=0644 /artefacts/mods/*.jar ./mods/
COPY --from=downloader --chmod=0644 /artefacts/datapacks/*.zip ./universe/world/datapacks/

ENTRYPOINT ["/bin/docker-entrypoint"]
