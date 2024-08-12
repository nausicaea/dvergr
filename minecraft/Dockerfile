FROM docker.io/library/eclipse-temurin:21-jre-alpine@sha256:3f716d52e4045433e94a28d029c93d3c23179822a5d40b1c82b63aedd67c5081
VOLUME ["/var/lib/minecraft/.cache", "/var/lib/minecraft/management", "/var/lib/minecraft/universe"]
EXPOSE 25565/tcp
ARG MINECRAFT_VERSION=1.21.1
ARG MINECRAFT_SERVER_ID=minecraft
ENV JAVA_INITIAL_MEM=256m
ENV JAVA_MAX_MEM=2g

ADD --checksum=sha256:c3ad3e23eee860e5185c594e7cb280e4fabe7e766a83945381d9a99c64855c5b https://quiltmc.org/api/v1/download-latest-installer/java-universal /tmp/quilt-installer.jar
RUN <<-EOF
    set -ex;
    addgroup -S minecraft;
    adduser -S -G minecraft -h /var/lib/minecraft -g "Minecraft Server" -s /bin/sh minecraft;
    java -jar /tmp/quilt-installer.jar install server ${MINECRAFT_VERSION} --download-server --install-dir=/usr/local/lib/minecraft;
EOF

WORKDIR /var/lib/minecraft
COPY <<-EOF quilt-server-launcher.properties
    serverJar=/usr/local/lib/minecraft/server.jar
EOF
COPY eula.txt eula.txt
COPY log4j2.xml log4j2.xml
COPY server.properties server.properties
RUN <<-EOF
    set -ex;
    java -jar /usr/local/lib/minecraft/quilt-server-launch.jar --initSettings;
    mkdir management;
    touch management/ops.json management/whitelist.json management/banned-ips.json management/banned-players.json;
    ln -s management/ops.json ops.json;
    ln -s management/whitelist.json whitelist.json;
    ln -s management/banned-ips.json banned-ips.json;
    ln -s management/banned-players.json banned-players.json;
    mkdir universe;
    chown -R minecraft:minecraft .;
EOF
COPY --chmod=0755 <<-"EOF" /bin/docker-entrypoint
#!/bin/sh

AIKAR_FLAGS=" \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
"

exec java \
    -Xms${JAVA_INITIAL_MEM} \
    -Xmx${JAVA_MAX_MEM} \
    ${AIKAR_FLAGS} \
    -Dlog4j.configurationFile=/var/lib/minecraft/log4j2.xml \
    -jar /usr/local/lib/minecraft/quilt-server-launch.jar \
    --serverId ${MINECRAFT_SERVER_ID} \
    --universe /var/lib/minecraft/universe \
    --nogui
EOF

USER minecraft:minecraft
ENTRYPOINT ["/bin/docker-entrypoint"]
