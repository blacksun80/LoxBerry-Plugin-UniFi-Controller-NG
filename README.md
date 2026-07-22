# UniFi Controller NG (LoxBerry Plugin)

Runs the [UniFi Network Application](https://www.ui.com/) (the successor of the
discontinued *UniFi Controller*) in Docker on
[LoxBerry](https://www.loxberry.de), together with its required MongoDB, and
integrates it into the LoxBerry web UI.

This is a fresh, LoxBerry-**V4-native** plugin (LoxBerry Design System, LoxBerry
PHP libraries). It is 64-bit only.

## Requirements

- **64-bit LoxBerry** (Raspberry Pi 4/5 or x86, LoxBerry 4.0+). Enforced via the
  `ARCHITECTURE` field in `plugin.cfg` (`aarch64,x86_64`) — the plugin manager
  refuses to install on 32-bit, because the UniFi Network Application and MongoDB
  are only published as 64-bit images.
- A running **Docker Engine** with the `docker compose` v2 plugin, reachable by
  user `loxberry` (`/var/run/docker.sock`).
- Roughly **1–2 GB RAM** free (Java application + MongoDB).

## Features

- UniFi Network Application + MongoDB as two Docker containers.
- Version switcher, service status, live diagnostics.
- Auto-generated MongoDB password (no secret in the repo).

## Credits

This plugin is based on the original
[LoxBerry-Plugin-Unfi-Controller](https://github.com/romanlum/LoxBerry-Plugin-Unfi-Controller)
by **Roman Lumetsberger**. Thank you for the original work that this builds on!

## License

Licensed under the [MIT](LICENSE) License.
