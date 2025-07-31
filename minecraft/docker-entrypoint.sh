#!/bin/sh

# For an explanation, see https://docs.papermc.io/paper/aikars-flags
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

# Defines command line options for the Java invocation
JAVA_OPTS=" \
    -Xms${JAVA_INITIAL_MEM:-256m} \
    -Xmx${JAVA_MAX_MEM:-4G} \
    ${AIKAR_FLAGS} \
    -Dlog4j.configurationFile=/var/lib/minecraft/server-config/log4j2.xml \
"

if [ -n "${OTEL_EXPORTER_OTLP_ENDPOINT}" ]; then
    JAVA_OPTS="$JAVA_OPTS \
        -Dotel.javaagent.configuration-file=/var/lib/minecraft/server-config/opentelemetry.properties \
        -javaagent:/usr/local/lib/opentelemetry-javaagent.jar \
    "
fi

exec /opt/java/openjdk/bin/java \
    ${JAVA_OPTS} \
    -jar /usr/local/lib/fabric-launcher.jar \
    --serverId "${MINECRAFT_SERVER_ID:-minecraft}" \
    --universe /var/lib/minecraft/universe \
    --nogui
