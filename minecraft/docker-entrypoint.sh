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

# 
export CLASSPATH="\
/usr/local/lib/*:\
/usr/local/lib/minecraft/*:\
/var/lib/minecraft/libraries/com/github/oshi/oshi-core/6.2.2/oshi-core-6.2.2.jar:\
/var/lib/minecraft/libraries/com/google/code/gson/gson/2.10/gson-2.10.jar:\
/var/lib/minecraft/libraries/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar:\
/var/lib/minecraft/libraries/com/google/guava/guava/31.1-jre/guava-31.1-jre.jar:\
/var/lib/minecraft/libraries/com/mojang/authlib/4.0.43/authlib-4.0.43.jar:\
/var/lib/minecraft/libraries/com/mojang/brigadier/1.1.8/brigadier-1.1.8.jar:\
/var/lib/minecraft/libraries/com/mojang/datafixerupper/6.0.8/datafixerupper-6.0.8.jar:\
/var/lib/minecraft/libraries/com/mojang/logging/1.1.1/logging-1.1.1.jar:\
/var/lib/minecraft/libraries/commons-io/commons-io/2.11.0/commons-io-2.11.0.jar:\
/var/lib/minecraft/libraries/io/netty/netty-buffer/4.1.82.Final/netty-buffer-4.1.82.Final.jar:\
/var/lib/minecraft/libraries/io/netty/netty-codec/4.1.82.Final/netty-codec-4.1.82.Final.jar:\
/var/lib/minecraft/libraries/io/netty/netty-common/4.1.82.Final/netty-common-4.1.82.Final.jar:\
/var/lib/minecraft/libraries/io/netty/netty-handler/4.1.82.Final/netty-handler-4.1.82.Final.jar:\
/var/lib/minecraft/libraries/io/netty/netty-resolver/4.1.82.Final/netty-resolver-4.1.82.Final.jar:\
/var/lib/minecraft/libraries/io/netty/netty-transport/4.1.82.Final/netty-transport-4.1.82.Final.jar:\
/var/lib/minecraft/libraries/io/netty/netty-transport-classes-epoll/4.1.82.Final/netty-transport-classes-epoll-4.1.82.Final.jar:\
/var/lib/minecraft/libraries/io/netty/netty-transport-native-epoll/4.1.82.Final/netty-transport-native-epoll-4.1.82.Final-linux-x86_64.jar:\
/var/lib/minecraft/libraries/io/netty/netty-transport-native-epoll/4.1.82.Final/netty-transport-native-epoll-4.1.82.Final-linux-aarch_64.jar:\
/var/lib/minecraft/libraries/io/netty/netty-transport-native-unix-common/4.1.82.Final/netty-transport-native-unix-common-4.1.82.Final.jar:\
/var/lib/minecraft/libraries/it/unimi/dsi/fastutil/8.5.9/fastutil-8.5.9.jar:\
/var/lib/minecraft/libraries/net/java/dev/jna/jna/5.12.1/jna-5.12.1.jar:\
/var/lib/minecraft/libraries/net/java/dev/jna/jna-platform/5.12.1/jna-platform-5.12.1.jar:\
/var/lib/minecraft/libraries/net/sf/jopt-simple/jopt-simple/5.0.4/jopt-simple-5.0.4.jar:\
/var/lib/minecraft/libraries/org/apache/commons/commons-lang3/3.12.0/commons-lang3-3.12.0.jar:\
/var/lib/minecraft/libraries/org/apache/logging/log4j/log4j-api/2.19.0/log4j-api-2.19.0.jar:\
/var/lib/minecraft/libraries/org/apache/logging/log4j/log4j-core/2.19.0/log4j-core-2.19.0.jar:\
/var/lib/minecraft/libraries/org/apache/logging/log4j/log4j-slf4j2-impl/2.19.0/log4j-slf4j2-impl-2.19.0.jar:\
/var/lib/minecraft/libraries/org/joml/joml/1.10.5/joml-1.10.5.jar:\
/var/lib/minecraft/libraries/org/slf4j/slf4j-api/2.0.1/slf4j-api-2.0.1.jar:\
/usr/local/lib/minecraft/libraries/org/ow2/asm/asm-util/9.6/asm-util-9.6.jar:\
/usr/local/lib/minecraft/libraries/org/quiltmc/quilt-loader/0.26.3/quilt-loader-0.26.3.jar:\
/usr/local/lib/minecraft/libraries/org/quiltmc/quilt-config/1.3.1/quilt-config-1.3.1.jar:\
/usr/local/lib/minecraft/libraries/org/ow2/asm/asm-analysis/9.6/asm-analysis-9.6.jar:\
/usr/local/lib/minecraft/libraries/org/ow2/asm/asm-tree/9.6/asm-tree-9.6.jar:\
/usr/local/lib/minecraft/libraries/net/fabricmc/access-widener/2.1.0/access-widener-2.1.0.jar:\
/usr/local/lib/minecraft/libraries/org/quiltmc/quilt-json5/1.0.4+final/quilt-json5-1.0.4+final.jar:\
/usr/local/lib/minecraft/libraries/net/fabricmc/tiny-remapper/0.10.1/tiny-remapper-0.10.1.jar:\
/usr/local/lib/minecraft/libraries/org/ow2/asm/asm/9.6/asm-9.6.jar:\
/usr/local/lib/minecraft/libraries/net/fabricmc/intermediary/1.21.1/intermediary-1.21.1.jar:\
/usr/local/lib/minecraft/libraries/net/fabricmc/sponge-mixin/0.13.3+mixin.0.8.5/sponge-mixin-0.13.3+mixin.0.8.5.jar:\
/usr/local/lib/minecraft/libraries/net/fabricmc/intermediary/1.21.1/intermediary-1.21.1.jar:\
/usr/local/lib/minecraft/libraries/net/fabricmc/tiny-mappings-parser/0.3.0+build.17/tiny-mappings-parser-0.3.0+build.17.jar:\
/usr/local/lib/minecraft/libraries/org/ow2/asm/asm-commons/9.6/asm-commons-9.6.jar\
"

# Defines command line options for the Java invocation
JAVA_OPTS=" \
    -Xms${JAVA_INITIAL_MEM} \
    -Xmx${JAVA_MAX_MEM} \
    ${AIKAR_FLAGS} \
    -Dlog4j.configurationFile=/var/lib/minecraft/log4j2.xml \
    -Dotel.javaagent.configuration-file=/var/lib/minecraft/opentelemetry.properties \
    -javaagent:/usr/local/lib/opentelemetry-javaagent.jar \
"

exec java \
    ${JAVA_OPTS} \
    org.quiltmc.loader.impl.launch.server.QuiltServerLauncher \
    --serverId ${MINECRAFT_SERVER_ID} \
    --universe /var/lib/minecraft/universe \
    --nogui
