package net.nausicaea.otel;

import net.fabricmc.api.ModInitializer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Otel implements ModInitializer {
    public static final Logger LOGGER = LoggerFactory.getLogger(Otel.class);

	@Override
	public void onInitialize() {
		LOGGER.info("OpenTelemetry logging instrumentation loaded");
	}
}
