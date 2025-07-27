package net.nausicaea.otel.mixin;

import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.instrumentation.log4j.appender.v2_17.OpenTelemetryAppender;
import net.minecraft.server.Main;
import net.nausicaea.otel.Otel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Main.class)
public class OtelMixin {
    @Inject(method = "main", at = @At("HEAD"))
    private static void initLogging(CallbackInfo info) {
        Logger mixinLogger = LoggerFactory.getLogger(Otel.class);

        mixinLogger.info("Obtain a reference to the global OpenTelemetry object (managed by the Java agent)");
        OpenTelemetry otel = GlobalOpenTelemetry.get();

        mixinLogger.info("Install the OpenTelemetry appender in Log4j");
        OpenTelemetryAppender.install(otel);

    }
}
