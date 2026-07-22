# CLAUDE.md - UniFi Controller NG (LoxBerry plugin)

A LoxBerry **V4-native** plugin (LoxBerry Design System + LoxBerry PHP libraries,
no Symfony/Poppins). Runs the UniFi Network Application + MongoDB in Docker.
Repo `blacksun80/LoxBerry-Plugin-UniFi-Controller-NG`. Based on Roman
Lumetsberger's original plugin.

There is no build/test toolchain: the plugin is a ZIP installed via the LoxBerry
web UI; the feedback loop is the install log plus the plugin's pages and SSH.

## Layout

- `plugin.cfg` - metadata. `NAME`/`FOLDER=unifing`, `INTERFACE=2.0`,
  `LB_MINIMUM=4.0.0`, `ARCHITECTURE=aarch64,x86_64` (the plugin manager blocks
  32-bit; no arm32 images exist for the app/MongoDB).
- Lifecycle (root/loxberry per V4): `preroot.sh` (root), `preupgrade.sh`,
  `preinstall.sh`, `postinstall.sh`, `postupgrade.sh` (loxberry), `postroot.sh`
  (root). `uninstall/uninstall.sh` (root). `sbin/unifing_ctl.sh` (auto-granted
  sudo).
- `data/docker/` - `docker-compose.yml`, `init-mongo.js`, `unifing.service`.
  Deployed to `LBHOMEDIR/data/plugins/unifing/docker/`.
- `webfrontend/htmlauth/index.php` - main frontend (auth-protected).
- `templates/` - `main.html`, `diagnostics.html`, `help/help.html`, `lang/language_{de,en}.ini`.
- `icons/icon.svg`.

## Runtime facts

- Docker names: app container `unifing-app`, db container `unifing-db`, systemd
  service `unifing`, compose project `unifing` (set via `name:`), network
  `unifing_default`.
- **Named volumes** `unifing-appdata` (/config) and `unifing-dbdata` (/data/db)
  hold the UniFi config and MongoDB data. They persist independently of the
  plugin folder, so they survive a plugin update (which deletes+recreates the
  folder) without copying data to /tmp. Removed on uninstall.
- `config/plugins/unifing/env` is the compose `.env` (symlinked to
  `data/plugins/unifing/docker/.env` by postroot): `VERSION=` and `MONGO_PASS=`.
  `pre/postupgrade` preserve this file across updates (the password must stay).
- `config/plugins/unifing/unifi.env` holds `PUID`/`PGID` (written by postinstall).
- **MONGO_PASS** is generated once in `postroot.sh` (random 32 chars, `tr -dc
  'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 32` - stderr redirected
  because tr hits a harmless broken pipe), stored in env and written into
  `init-mongo.js` (sed on `MONGO_PASS_PLACEHOLDER`).
- Frontend writes only the `VERSION=` line of the env (line-aware, keeps
  MONGO_PASS). Version change / reset run via `sudo REPLACELBPSBINDIR/unifing_ctl.sh`.
- Diagnostics reads `server.log` via `docker exec unifing-app tail
  /config/logs/server.log` (it lives in the named volume, not a host path).

## Gotchas (from the predecessor branch, still apply)

- `MEM_LIMIT` must be a plain number, not `1024M` (the image appends `M`).
- `1900/udp` (SSDP) must NOT be mapped: LoxBerry already binds it.
- The version dropdown only offers Docker Hub tags that have a multi-arch image
  matching the host architecture.
- The `Manifest request to ULP failed ... 127.0.0.1:9080 ... refused` log lines
  are cosmetic (UniFi OS is not present in a bare container).
- Inform host in the modern UI: **UniFi Devices -> Device Updates and Settings
  -> Device SSH Settings -> Inform Host Override**.
- `REPLACELBP*` placeholders are replaced in ALL delivered text files (.php,
  .service, .yml, .sh). Never hardcode `/opt/loxberry` (install warning).
- Line endings are pinned to LF via `.gitattributes`.

## Not yet verified

The frontend was written against the documented LoxBerry V4 PHP API but not run
on a real LoxBerry. Verify on first install: rendering (LBWeb/LBSystem calls),
version change + reset (sbin auto-sudo), diagnostics window, REPLACE substitution.
