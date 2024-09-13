package net.nausicaea.otel.mixin;

import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.instrumentation.log4j.appender.v2_17.OpenTelemetryAppender;
import net.minecraft.server.MinecraftServer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import java.util.function.Function;

@Mixin(MinecraftServer.class)
public class OtelMixin {
	@Inject(method = "startServer", at = @At("HEAD"))
	private static <S extends MinecraftServer> void startServer(Function<Thread, S> serverFactory, CallbackInfoReturnable<S> cir) {
        Logger mixinLogger = LoggerFactory.getLogger(OtelMixin.class);

		mixinLogger.info("Obtain a reference to the global OpenTelemetry object");
		OpenTelemetry otel = GlobalOpenTelemetry.get();

		mixinLogger.info("Find OpenTelemetryAppender in log4j configuration and install openTelemetrySdk");
		OpenTelemetryAppender.install(otel);
	}
}
