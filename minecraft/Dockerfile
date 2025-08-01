# syntax=docker/dockerfile:1

### Builds the Modrinth downloader used in the downloader build step
FROM docker.io/library/rust:1.88.0-alpine3.22 AS builder_a
ARG TARGETARCH
ARG TARGETOS
ARG OPENSSL_STATIC=1
ARG OPENSSL_LIB_DIR=/usr/lib
ARG OPENSSL_INCLUDE_DIR=/usr/include
#ARG SCCACHE_VERSION
#ARG SCCACHE_CHECKSUM
#ARG AWS_ACCESS_KEY_ID
#ARG AWS_SECRET_ACCESS_KEY
#ARG SCCACHE_BUCKET
#ARG SCCACHE_ENDPOINT
#ARG SCCACHE_REGION=auto
#ARG SCCACHE_S3_USE_SSL=true
#ARG SCCACHE_S3_SERVER_SIDE_ENCRYPTION=true
#ARG RUSTC_WRAPPER=/usr/local/bin/sccache
ARG CARGO_REGISTRY=/root/.cargo/registry
RUN apk add --no-cache openssl-libs-static openssl-dev musl-dev
# WORKDIR /tmp
# ADD --link --checksum=${SCCACHE_CHECKSUM} https://github.com/mozilla/sccache/releases/download/${SCCACHE_VERSION}/sccache-${SCCACHE_VERSION}-${TARGETARCH}-unknown-${TARGETOS}-musl.tar.gz ./sccache-${SCCACHE_VERSION}.tar.gz
# RUN <<-EOF
# set -ex;
# tar -xzf ./sccache-${SCCACHE_VERSION}.tar.gz sccache-${SCCACHE_VERSION}/sccache;
# install -o root -g root -m 0755 ./sccache-${SCCACHE_VERSION}/sccache /usr/local/bin/sccache;
# sccache --show-stats;
# EOF
WORKDIR /src
COPY --link modrinth/Cargo.toml .
COPY --link modrinth/Cargo.lock .
COPY --link modrinth/src ./src
RUN --mount=type=cache,target=/root/.cargo cargo fetch
RUN --mount=type=cache,target=/root/.cargo --mount=type=cache,target=/src/target cargo build --locked --release
WORKDIR /artefacts
RUN --mount=type=cache,target=/src/target cp /src/target/release/modrinth /artefacts/modrinth

### Builds the Opentelemetry integration as a mod for fabric
FROM docker.io/library/gradle:8.14.2-jdk21-alpine AS builder_b
ARG MINECRAFT_VERSION
ARG YARN_MAPPINGS_VERSION
ARG FABRIC_LOADER_VERSION
WORKDIR /src
COPY --link otel-mod/build.gradle ./
COPY --link otel-mod/settings.gradle ./
COPY --link otel-mod/gradle.properties ./
COPY --link otel-mod/src ./src
RUN --mount=type=cache,target=/root/.gradle --mount=type=cache,target=/src/.gradle gradle --no-daemon --build-cache :dependencies
RUN --mount=type=cache,target=/root/.gradle --mount=type=cache,target=/src/.gradle gradle --no-daemon --build-cache :assemble
WORKDIR /artefacts
RUN cp /src/build/libs/otel-0.0.0.jar /artefacts/otel-0.0.0.jar

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
FROM docker.io/library/alpine:3.22 AS downloader
ARG MINECRAFT_VERSION
ARG FABRIC_LOADER_VERSION
ARG FABRIC_LOADER_CHECKSUM
ARG FABRIC_INSTALLER_VERSION
ARG OTEL_JAVAAGENT_VERSION
ARG OTEL_JAVAAGENT_CHECKSUM
ARG JOLOKIA_JAVAAGENT_VERSION
ARG JOLOKIA_JAVAAGENT_CHECKSUM
ADD --link --checksum=${FABRIC_LOADER_CHECKSUM} https://meta.fabricmc.net/v2/versions/loader/${MINECRAFT_VERSION}/${FABRIC_LOADER_VERSION}/${FABRIC_INSTALLER_VERSION}/server/jar /artefacts/lib/fabric-launcher.jar
ADD --link --checksum=${OTEL_JAVAAGENT_CHECKSUM} https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_JAVAAGENT_VERSION}/opentelemetry-javaagent.jar /artefacts/lib/opentelemetry-javaagent.jar
ADD --link --checksum=${JOLOKIA_JAVAAGENT_CHECKSUM} https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-agent-jvm/${JOLOKIA_JAVAAGENT_VERSION}/jolokia-agent-jvm-${JOLOKIA_JAVAAGENT_VERSION}-javaagent.jar /artefacts/lib/jolokia-javaagent.jar
COPY --from=builder_a --chmod=0755 /artefacts/modrinth /bin/modrinth
RUN --mount=type=secret,id=MODRINTH_PAT,env=MODRINTH_PAT --mount=type=bind,target=/tmp/Modrinth.toml,source=./Modrinth.toml --mount=type=bind,target=/tmp/Modrinth.lock,source=./Modrinth.lock <<-EOC
set -xe;
mkdir -p /artefacts;
export RUST_LOG="modrinth=debug";
/bin/modrinth -o /artefacts -s --lockfile /tmp/Modrinth.lock --manifest /tmp/Modrinth.toml;
EOC

### Builds and runs the final image
FROM docker.io/library/alpine:3.22
ARG MINECRAFT_VERSION
ENV MINECRAFT_SERVER_ID=minecraft
ENV JAVA_INITIAL_MEM=256M
ENV JAVA_MAX_MEM=2G
ENV OTEL_EXPORTER_OTLP_ENDPOINT=""
ENV JOLOKIA_BIND_ADDRESS=""
COPY --from=builder_c /artefacts/optimized-jdk-21 /opt/java/customjdk
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
COPY --link --chown=10001:10001 server-icon.png ./
COPY --link --chown=10001:10001 eula.txt server.properties log4j2.xml opentelemetry.properties ./server-config/
COPY --from=builder_b --chown=10001:10001 /artefacts/otel-0.0.0.jar ./mods/
COPY --from=downloader --chown=10001:10001 /artefacts/fabric/*.jar ./mods/
COPY --from=downloader --chown=10001:10001 /artefacts/datapack/*.zip ./universe/world/datapacks/
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
find . -type d -exec chmod 0755 {} \+;
find . -type f -exec chmod 0644 {} \+;
EOC
USER minecraft:minecraft

# Pre-condition the server environment (--initSettings won't work due to a read-only server.properties)
RUN /bin/docker-entrypoint --help

### Last-ditch Optimizations
# find /usr/local/lib /var/lib/minecraft/libraries /var/lib/minecraft/mods /var/lib/minecraft/versions -type f -name "*.jar" -exec zip -d {} 'META-INF/*.SF' 'META-INF/*.RSA' 'LICENSE*' 'README*' \;
# curl -LO "https://storage.googleapis.com/r8-releases/raw/8.11.18/r8.jar"
# java -cp r8.jar com.android.tools.r8.R8 --help

EXPOSE 30000/tcp 30000/udp
ENTRYPOINT ["/bin/docker-entrypoint"]
