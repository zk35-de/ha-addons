# zk35 Home Assistant Add-ons

Home Assistant add-ons for running **multiple ebusd instances** — e.g. separate heating bus and ventilation bus.

## Why?

[LukasGrebe/ha-addons](https://github.com/LukasGrebe/ha-addons) provides an excellent single ebusd add-on.
If your home has **separate eBUS systems** (heating + ventilation on independent buses), you need two independent
instances with separate devices, configs, and MQTT topics. This repository provides exactly that.

## Installation

[![Add repository to Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fzk35-de%2Fha-addons)

Or manually: **Settings → Add-ons → ⋮ → Repositories** and add:
```
https://github.com/zk35-de/ha-addons
```

## Add-ons

### eBUSd Heating

Dedicated ebusd instance for your heating eBUS.

- Slug: `ebusd_heating`
- Config folder: `/addon_configs/ebusd_heating/`
- TCP port: 8888 (not exposed by default)
- Web terminal: HA ingress on port 7681

### eBUSd Ventilation

Dedicated ebusd instance for your ventilation eBUS.

- Slug: `ebusd_ventilation`
- Config folder: `/addon_configs/ebusd_ventilation/`
- TCP port: 8888 (not exposed by default)

Both add-ons run simultaneously without port conflicts. Each gets its own isolated config folder.

## Configuration

```yaml
# USB serial adapter:
device: /dev/ttyUSB0

# Network adapter (takes priority over USB if both set):
network_device: "192.168.1.10:9999"

# Additional ebusd flags (one per list entry):
commandline_options:
  - "--mqttjson"
  - "--mqtttopic=ebusd/heating"    # use different topics for each instance!
  - "--configpath=/config/csv"      # CSV device config files in your addon config folder
  - "--scanconfig"
```

> **Tip:** Set `--mqtttopic=ebusd/heating` for the heating instance and
> `--mqtttopic=ebusd/ventilation` for ventilation so MQTT topics don't collide.

## CSV Device Configs

Place your device-specific CSV files in the add-on config folder:
- Heating: `/addon_configs/ebusd_heating/csv/`
- Ventilation: `/addon_configs/ebusd_ventilation/csv/`

Then add `--configpath=/config/csv` to `commandline_options`.

See [ebusd configuration](https://github.com/john30/ebusd/wiki/4.-Configuration) for details.

## Images

Pre-built images are published to GitHub Container Registry:

```
ghcr.io/zk35-de/ebusd-heating:latest
ghcr.io/zk35-de/ebusd-ventilation:latest
```

Images are rebuilt automatically when a new [john30/ebusd](https://github.com/john30/ebusd) release is detected (weekly check, auto-PR).

## Architecture

```
docker.io/john30/ebusd:{version}                     ← upstream ebusd binary
ghcr.io/home-assistant/amd64-base-debian:trixie      ← HA Supervisor base (bashio, s6)
ghcr.io/tsl0922/ttyd:latest                          ← web terminal for ingress
        ↓ GitHub Actions build
ghcr.io/zk35-de/ebusd-{heating,ventilation}:{version}
        ↓ HA Supervisor pull & run
HA Add-on (isolated config under /addon_configs/{slug}/)
```

## Credits

- [john30/ebusd](https://github.com/john30/ebusd) — the eBUS daemon
- [LukasGrebe/ha-addons](https://github.com/LukasGrebe/ha-addons) — original single-instance HA add-on (run.sh adapted from there, Apache 2.0)
- [tsl0922/ttyd](https://github.com/tsl0922/ttyd) — web terminal

## License

Apache License 2.0 — see [LICENSE](LICENSE)
