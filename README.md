# zk35 Home Assistant Add-ons

Home Assistant add-ons for running **multiple ebusd instances** — e.g. separate heating bus and ventilation bus.

## Why?

[LukasGrebe/ha-addons](https://github.com/LukasGrebe/ha-addons) provides an excellent single ebusd add-on.
If your home has **separate eBUS systems** (heating + ventilation on independent buses), you need two independent
instances with separate devices, configs, and MQTT topics.

This repository provides exactly that, with some additional differences:

- **Two independent add-ons** — each with its own isolated config folder and MQTT namespace
- **All common options configurable via HA UI** — no CLI knowledge or `commandline_options` strings needed
- **Write commands for HA** — `mqtt_int: write` seeds `mqtt-hassio.write.cfg` and enables switches/setpoints in HA (e.g. hot water boost, ventilation boost)
- **Auto-built images** — weekly upstream check rebuilds images automatically when a new [john30/ebusd](https://github.com/john30/ebusd) release is detected

## Installation

[![Add repository to Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fzk35-de%2Fha-addons)

Or manually: **Settings → Add-ons → ⋮ → Repositories** and add:
```
https://github.com/zk35-de/ha-addons
```

## Add-ons

### eBUSd Heating

- Slug: `ebusd_heating`
- Config folder: `/addon_configs/ebusd_heating/`
- Default MQTT topic: `heating`
- Default mqtt_int: `write` (HA write commands enabled)

### eBUSd Ventilation

- Slug: `ebusd_ventilation`
- Config folder: `/addon_configs/ebusd_ventilation/`
- Default MQTT topic: `ventilation`
- Default mqtt_int: `standard` (read-only sensors)

Both add-ons run simultaneously without port conflicts. Each gets its own isolated config folder automatically.

## Configuration

All options are configurable via the HA add-on UI. No manual CLI flags required for typical setups.

| Option | Default | Description |
|---|---|---|
| `device` | _(none)_ | Serial device, e.g. `/dev/ttyUSB0` (USB adapter) |
| `network_device` | _(none)_ | Network adapter, e.g. `192.168.1.10:9999` (takes priority over USB) |
| `mqtt_topic` | `heating` / `ventilation` | MQTT topic prefix — must differ between instances |
| `mqtt_client_id` | _(auto)_ | MQTT client ID — leave empty for ebusd auto-generate |
| `mqtt_int` | `write` / `standard` | `write` = enable HA write commands (switches, setpoints); `standard` = read-only sensors |
| `mqtt_var` | `area=Heating` | Extra MQTT variables (passed as `--mqttvar`) |
| `scan_config` | `full` | ebusd scan config: `full`, `none`, or a device path |
| `poll_interval` | `5` | Polling interval in seconds (0 = disabled) |
| `access_level` | `*` | ebusd access level |
| `receive_timeout` | `100000` | Receive timeout in microseconds |
| `log_level` | `all:error` | Log level, e.g. `all:notice`, `main:info,bus:debug` |
| `commandline_options` | `[]` | Additional ebusd flags for advanced/unsupported options |

### mqtt_int: write

Setting `mqtt_int` to `write` seeds `mqtt-hassio.write.cfg` from the ebusd image into your addon config folder
(`/addon_configs/{slug}/mqtt-hassio.write.cfg`) on first start. This config enables the write direction
(`filter-direction = r|u|^w`), which creates writable entities in Home Assistant — e.g. hot water boost
(Warmwassertaste), ventilation boost (Stoßlüften), setpoints.

Setting it to `standard` uses `mqtt-hassio.cfg` (read-only sensors only).

### Preserving existing HA entities

If you are migrating from a custom ebusd setup, use the same `mqtt_topic` and `mqtt_client_id` as before.
MQTT entity IDs in Home Assistant are derived from these values — changing them would orphan your existing
dashboards, automations, and scripts.

## CSV Device Configs

By default both add-ons use john30's built-in device CSV files (no `--configpath` needed).

To use custom CSV files, place them in the add-on config folder and add to `commandline_options`:
```yaml
commandline_options:
  - "--configpath=/config/csv"
```

See [ebusd configuration](https://github.com/john30/ebusd/wiki/4.-Configuration) for details.

## Images

Pre-built multi-arch images (amd64, aarch64, armv7) are published to GitHub Container Registry:

```
ghcr.io/zk35-de/ebusd-heating-amd64:latest
ghcr.io/zk35-de/ebusd-ventilation-amd64:latest
```

Images are rebuilt automatically when a new [john30/ebusd](https://github.com/john30/ebusd) release is detected
(weekly check, auto-commit → triggers build).

## Architecture

```
docker.io/john30/ebusd:{version}                     ← upstream ebusd binary + CSV configs
ghcr.io/home-assistant/amd64-base-debian:trixie      ← HA Supervisor base (bashio, s6)
ghcr.io/tsl0922/ttyd:latest                          ← web terminal for HA ingress
        ↓ GitHub Actions build (QEMU multi-arch)
ghcr.io/zk35-de/ebusd-{heating,ventilation}-{arch}:{version}
        ↓ HA Supervisor pull & run
HA Add-on (isolated config under /addon_configs/{slug}/)
```

## Credits

- [john30/ebusd](https://github.com/john30/ebusd) — the eBUS daemon
- [LukasGrebe/ha-addons](https://github.com/LukasGrebe/ha-addons) — original single-instance HA add-on (Apache 2.0)
- [tsl0922/ttyd](https://github.com/tsl0922/ttyd) — web terminal

## License

Apache License 2.0 — see [LICENSE](LICENSE)
