#!/usr/bin/with-contenv bashio
# ebusd run script for HA Supervisor add-on.
# /config/ maps to /addon_configs/<slug>/ – automatically isolated per addon instance.

bashio::log.info "eBUSd addon version $(bashio::addon.version)"

declare -a ebusd_args
ebusd_args+=(
    "--foreground"
    "--updatecheck=off"
)

# MQTT via HA Supervisor service discovery
if bashio::services.available 'mqtt'; then
    ebusd_args+=(
        "--mqtthost=$(bashio::services mqtt 'host')"
        "--mqttport=$(bashio::services mqtt 'port')"
        "--mqttuser=$(bashio::services mqtt 'username')"
        "--mqttpass=$(bashio::services mqtt 'password')"
        "--mqttjson"
        "--mqttint=/config/mqtt-hassio.cfg"
    )
else
    bashio::log.warning "MQTT service not available via Supervisor. Pass --mqtt* via commandline_options to use an external broker."
fi

# Seed default MQTT integration config if not present
if [ ! -f /config/mqtt-hassio.cfg ]; then
    bashio::log.info "Seeding default mqtt-hassio.cfg into addon config folder"
    cp /etc/ebusd/mqtt-hassio.cfg /config/mqtt-hassio.cfg
fi

# Device configuration (network takes priority over USB)
if bashio::config.has_value "network_device"; then
    if bashio::config.has_value "device"; then
        bashio::log.warning "Both 'device' and 'network_device' configured – using network_device."
    fi
    ebusd_args+=("--device=$(bashio::config 'network_device')")
elif bashio::config.has_value "device"; then
    ebusd_args+=("--device=$(bashio::config 'device')")
else
    bashio::log.info "No device configured – ebusd will attempt mDNS auto-discovery."
fi

# Start web terminal on ingress port
ttyd --port 7681 --writable bash >/dev/null 2>&1 &

# Extra commandline_options (list of flags from addon config)
while IFS= read -r _opt; do
    [ -n "${_opt}" ] && ebusd_args+=("${_opt}")
done < <(jq -r '.commandline_options[]?' /data/options.json 2>/dev/null)

# Log command (credentials redacted)
bashio::log.info "ebusd $(printf '%s ' "${ebusd_args[@]}" \
    | sed 's/--mqttuser=[^ ]*/--mqttuser=<redacted>/g; s/--mqttpass=[^ ]*/--mqttpass=<redacted>/g')"

exec ebusd "${ebusd_args[@]}"
