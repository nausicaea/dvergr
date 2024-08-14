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
    -Dlog4j.configurationFile=/var/lib/minecraft/server/log4j2.xml \
    -Dotel.javaagent.configuration-file=/var/lib/minecraft/server/opentelemetry.properties \
    -javaagent:/usr/local/lib/opentelemetry-javaagent.jar \
    -jar /usr/local/lib/minecraft/quilt-server-launch.jar \
    --serverId ${MINECRAFT_SERVER_ID} \
    --universe /var/lib/minecraft/universe \
    --nogui
