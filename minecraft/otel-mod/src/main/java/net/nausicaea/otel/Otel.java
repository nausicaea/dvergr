package net.nausicaea.otel;

import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.instrumentation.log4j.appender.v2_17.OpenTelemetryAppender;
import net.fabricmc.loader.api.entrypoint.PreLaunchEntrypoint;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Otel implements PreLaunchEntrypoint {
    public static final Logger LOGGER = LoggerFactory.getLogger(Otel.class);

	@Override
	public void onPreLaunch() {
		LOGGER.info("Obtain a reference to the global OpenTelemetry object (managed by the Java agent)");
		OpenTelemetry otel = GlobalOpenTelemetry.get();

		LOGGER.info("Install the OpenTelemetry appender in Log4j");
		OpenTelemetryAppender.install(otel);

		LOGGER.info("OpenTelemetry logging instrumentation is loaded");
	}
}
