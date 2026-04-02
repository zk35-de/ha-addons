#!/usr/bin/with-contenv bashio
# ebusd run script for HA Supervisor add-on.
# All options configurable via HA UI – no manual CLI knowledge needed.

bashio::log.info "eBUSd addon version $(bashio::addon.version)"

declare -a ebusd_args
ebusd_args+=(
    "--foreground"
    "--updatecheck=off"
)

# ---------------------------------------------------------------------------
# MQTT – from HA Supervisor service discovery
# ---------------------------------------------------------------------------
if bashio::services.available 'mqtt'; then
    ebusd_args+=(
        "--mqtthost=$(bashio::services mqtt 'host')"
        "--mqttport=$(bashio::services mqtt 'port')"
        "--mqttuser=$(bashio::services mqtt 'username')"
        "--mqttpass=$(bashio::services mqtt 'password')"
        "--mqttjson"
    )
else
    bashio::log.warning "MQTT service not available. Pass --mqtt* via commandline_options if using external broker."
fi

# MQTT topic prefix (e.g. "heating" or "ventilation")
ebusd_args+=("--mqtttopic=$(bashio::config 'mqtt_topic')")

# MQTT client ID (optional – leave empty for ebusd auto-generate)
if bashio::config.has_value 'mqtt_client_id'; then
    CLIENT_ID=$(bashio::config 'mqtt_client_id')
    [[ -n "${CLIENT_ID}" ]] && ebusd_args+=("--mqttclientid=${CLIENT_ID}")
fi

# MQTT integration config file
# "write"    → mqtt-hassio.write.cfg  (enables HA write commands – switches, setpoints, etc.)
# "standard" → mqtt-hassio.cfg        (read-only sensors only)
# any other  → treated as absolute path inside the addon config folder
MQTT_INT=$(bashio::config 'mqtt_int' 'write')
case "${MQTT_INT}" in
    write)    SRC="/etc/ebusd/mqtt-hassio.write.cfg" ;;
    standard) SRC="/etc/ebusd/mqtt-hassio.cfg" ;;
    *)        SRC="${MQTT_INT}" ;;
esac
if [[ "${SRC}" == /etc/ebusd/* ]]; then
    BASENAME=$(basename "${SRC}")
    TARGET="/config/${BASENAME}"
    if [ ! -f "${TARGET}" ]; then
        if [ -f "${SRC}" ]; then
            bashio::log.info "Seeding ${BASENAME} into addon config folder"
            cp "${SRC}" "${TARGET}"
        else
            bashio::log.warning "${SRC} not found in image – skipping --mqttint"
            TARGET=""
        fi
    fi
    [[ -n "${TARGET}" ]] && ebusd_args+=("--mqttint=${TARGET}")
else
    ebusd_args+=("--mqttint=${SRC}")
fi

# MQTT var (e.g. "area=Heating")
if bashio::config.has_value 'mqtt_var'; then
    VAR=$(bashio::config 'mqtt_var')
    [[ -n "${VAR}" ]] && ebusd_args+=("--mqttvar=${VAR}")
fi

# ---------------------------------------------------------------------------
# Device – network adapter takes priority over USB
# ---------------------------------------------------------------------------
if bashio::config.has_value 'network_device'; then
    if bashio::config.has_value 'device'; then
        bashio::log.warning "Both 'device' and 'network_device' configured – using network_device."
    fi
    ebusd_args+=("--device=$(bashio::config 'network_device')")
elif bashio::config.has_value 'device'; then
    ebusd_args+=("--device=$(bashio::config 'device')")
else
    bashio::log.info "No device configured – ebusd will attempt mDNS auto-discovery."
fi

# ---------------------------------------------------------------------------
# Misc options
# ---------------------------------------------------------------------------
SCAN=$(bashio::config 'scan_config' 'full')
[[ -n "${SCAN}" && "${SCAN}" != "off" ]] && ebusd_args+=("--scanconfig=${SCAN}")

POLL=$(bashio::config 'poll_interval' '0')
[[ "${POLL}" -gt 0 ]] 2>/dev/null && ebusd_args+=("--pollinterval=${POLL}")

if bashio::config.has_value 'access_level'; then
    AL=$(bashio::config 'access_level')
    [[ -n "${AL}" ]] && ebusd_args+=("--accesslevel=${AL}")
fi

RTIMEOUT=$(bashio::config 'receive_timeout' '0')
[[ "${RTIMEOUT}" -gt 0 ]] 2>/dev/null && ebusd_args+=("--receivetimeout=${RTIMEOUT}")

if bashio::config.has_value 'log_level'; then
    LL=$(bashio::config 'log_level')
    [[ -n "${LL}" ]] && ebusd_args+=("--log=${LL}")
fi

# ---------------------------------------------------------------------------
# Extra commandline_options passthrough
# ---------------------------------------------------------------------------
while IFS= read -r _opt; do
    [ -n "${_opt}" ] && ebusd_args+=("${_opt}")
done < <(jq -r '.commandline_options[]?' /data/options.json 2>/dev/null)

# ---------------------------------------------------------------------------
# Start web terminal for HA ingress
# ---------------------------------------------------------------------------
ttyd --port 7681 --writable bash >/dev/null 2>&1 &

# Log (credentials redacted)
bashio::log.info "ebusd $(printf '%s ' "${ebusd_args[@]}" \
    | sed 's/--mqttuser=[^ ]*/--mqttuser=<redacted>/g; s/--mqttpass=[^ ]*/--mqttpass=<redacted>/g')"

exec ebusd "${ebusd_args[@]}"
