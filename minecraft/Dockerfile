# syntax=docker/dockerfile:1

FROM docker.io/library/gradle:8.10-jdk21-alpine AS builder
WORKDIR /src
COPY otel-mod /src
RUN --mount=type=cache,target=/src/.gradle gradle --no-daemon :assemble

FROM docker.io/library/eclipse-temurin:21-jre-alpine@sha256:3f716d52e4045433e94a28d029c93d3c23179822a5d40b1c82b63aedd67c5081
VOLUME ["/var/lib/minecraft/.cache", "/var/lib/minecraft/config", "/var/lib/minecraft/logs", "/var/lib/minecraft/mods", "/var/lib/minecraft/universe"]
EXPOSE 25565/tcp 24454/udp
ARG MINECRAFT_VERSION=1.21.1
ENV MINECRAFT_SERVER_ID=minecraft
ENV JAVA_INITIAL_MEM=256M
ENV JAVA_MAX_MEM=2G
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

COPY --chmod=0755 docker-entrypoint.sh /bin/docker-entrypoint
ADD --link --checksum=sha256:c3ad3e23eee860e5185c594e7cb280e4fabe7e766a83945381d9a99c64855c5b https://quiltmc.org/api/v1/download-latest-installer/java-universal /tmp/quilt-installer.jar
ADD --link --checksum=sha256:e77f7f3e2f2601a288bd8cb9deb7e2f9578034344e761587f51f03e097ae02ce --chmod=0644 https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v1.33.5/opentelemetry-javaagent.jar /usr/local/lib/
RUN set -xe; \
    addgroup -S minecraft; \
    adduser -S -G minecraft -h /var/lib/minecraft -g "Minecraft Server" -s /bin/sh minecraft; \
    java \
        -jar /tmp/quilt-installer.jar \
        install server ${MINECRAFT_VERSION} \
        --download-server \
        --install-dir=/usr/local/lib/minecraft; \
    rm /tmp/quilt-installer.jar

USER minecraft:minecraft
WORKDIR /var/lib/minecraft
COPY --chmod=0444 quilt-server-launcher.properties eula.txt ./
COPY --from=builder --chmod=0444 /src/build/libs/otel-1.0.0.jar ./builtin_mods/
COPY server.properties ./
RUN java -jar /usr/local/lib/minecraft/quilt-server-launch.jar --initSettings

ENTRYPOINT ["/bin/docker-entrypoint"]
