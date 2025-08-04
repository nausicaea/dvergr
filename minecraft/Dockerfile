# syntax=docker/dockerfile:1

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
FROM ghcr.io/nausicaea/nema:v0.1.3 AS downloader
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
COPY --link provocation-v0.1.0.zip /artefacts/datapack/
RUN --mount=type=secret,id=MODRINTH_PAT,env=MODRINTH_PAT --mount=type=bind,target=/tmp/Modrinth.toml,source=./Modrinth.toml --mount=type=bind,target=/tmp/Modrinth.lock,source=./Modrinth.lock <<-EOC
set -xe;
/usr/local/bin/modrinth -o /artefacts --strict -s --lockfile /tmp/Modrinth.lock --manifest /tmp/Modrinth.toml;
EOC

### Builds and runs the final image
FROM docker.io/library/alpine:3.22
VOLUME ["/var/lib/minecraft/persistent", "/etc/minecraft", "/var/cache/minecraft", "/var/log/minecraft"]
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
mkdir -v .cache .fabric .polydex cache polymer stackdeobf_mappings;
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
COPY --from=builder_b --chown=10001:10001 /artefacts/otel-0.0.0.jar ./mods/
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
ln -s /var/cache/minecraft/polymer ./polymer;
ln -s /var/cache/minecraft/stackdeobf_mappings ./stackdeobf_mappings;
# Logs (ephemeral)
ln -s /var/log/minecraft/crash-reports ./crash-reports;

# Fix ownership and permissions
chown -vR minecraft:minecraft .;
chmod -vR u=rwX,go=rX .;
EOF

# Drop down to the service user
USER minecraft:minecraft

# Pre-condition the server environment (--initSettings won't work due to a read-only server.properties)
RUN /usr/local/bin/docker-entrypoint --help

### Last-ditch Optimizations
# find /usr/local/lib /var/lib/minecraft/libraries /var/lib/minecraft/mods /var/lib/minecraft/versions -type f -name "*.jar" -exec zip -d {} 'META-INF/*.SF' 'META-INF/*.RSA' 'LICENSE*' 'README*' \;
# curl -LO "https://storage.googleapis.com/r8-releases/raw/8.11.18/r8.jar"
# java -cp r8.jar com.android.tools.r8.R8 --help

EXPOSE 30000/tcp 30000/udp
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
