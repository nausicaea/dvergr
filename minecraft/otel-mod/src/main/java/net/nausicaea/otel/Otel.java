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
		LOGGER.info("OpenTelemetry logging instrumentation is loaded");
	}
}
