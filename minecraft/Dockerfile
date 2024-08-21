# syntax=docker/dockerfile:1

FROM docker.io/library/gradle:8.10-jdk21-alpine AS builder
WORKDIR /src
COPY otel-mod /src
RUN --mount=type=cache,target=/src/.gradle gradle --no-daemon :assemble

FROM docker.io/library/eclipse-temurin:21-jre-alpine@sha256:3f716d52e4045433e94a28d029c93d3c23179822a5d40b1c82b63aedd67c5081
VOLUME ["/var/lib/minecraft/.fabric", "/var/lib/minecraft/config", "/var/lib/minecraft/logs", "/var/lib/minecraft/crash-reports", "/var/lib/minecraft/mods", "/var/lib/minecraft/universe"]
EXPOSE 30000/tcp 30001/udp
ARG MODRINTH_PAT
ARG MINECRAFT_VERSION
ENV MINECRAFT_SERVER_ID=minecraft
ENV MODRINTH_PAT=${MODRINTH_PAT}
ENV JAVA_INITIAL_MEM=256M
ENV JAVA_MAX_MEM=2G
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

RUN set -xe; \
    apk add curl jq; \
    addgroup -S minecraft; \
    adduser -S -G minecraft -h /var/lib/minecraft -g "Minecraft Server" -s /bin/sh minecraft
ADD --link --checksum=sha256:d5093ba83742ef496479db82cb384f70a7e84ab7029936d50f5622f651038c49 --chmod=0644 https://meta.fabricmc.net/v2/versions/loader/${MINECRAFT_VERSION}/0.16.2/1.0.1/server/jar /usr/local/lib/minecraft/fabric-launcher.jar
ADD --link --checksum=sha256:e77f7f3e2f2601a288bd8cb9deb7e2f9578034344e761587f51f03e097ae02ce --chmod=0644 https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v1.33.5/opentelemetry-javaagent.jar /usr/local/lib/
COPY --chmod=0755 docker-entrypoint.sh /bin/docker-entrypoint
COPY --chmod=0755 modrinth.sh /bin/modrinth

ENV MINECRAFT_VERSION=1.21
ENTRYPOINT ["/bin/sh"]

# USER minecraft:minecraft
# WORKDIR /var/lib/minecraft
# RUN java \
#     -jar /usr/local/lib/minecraft/fabric-launcher.jar \
#     --universe /var/lib/minecraft/universe \
#     --initSettings
# COPY eula.txt ./
# COPY mods ./mods
# COPY --from=builder /src/build/libs/otel-1.0.0.jar ./mods/
# COPY datapacks ./universe/world/datapacks
# 
# ENTRYPOINT ["/bin/docker-entrypoint"]
