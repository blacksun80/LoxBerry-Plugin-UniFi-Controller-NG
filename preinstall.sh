#!/bin/bash

# preinstall.sh - runs as user loxberry before the plugin files are copied.

# Docker is mandatory. Verify the daemon answers on its unix socket as this user
# (a working socket returns exit 0; any non-zero means missing/unreachable).
echo "<INFO> Checking if docker is available"
curl -s --unix-socket /var/run/docker.sock http://ping >/dev/null 2>&1
if [ "$?" != "0" ]; then
    echo "<ERROR> Docker is not available (docker socket did not respond)."
    echo "<ERROR> This plugin needs a running Docker Engine reachable as user"
    echo "<ERROR> loxberry (add loxberry to the docker group if needed)."
    exit 2
fi
echo "<OK> Docker is available"

# The old "UniFi Controller" plugin runs a second controller on the same ports
# (8443 etc.). Two controllers cannot run side by side, so refuse to install
# alongside it. The old plugin installs /etc/systemd/system/unifi.service.
if [ -f /etc/systemd/system/unifi.service ]; then
    echo "<ERROR> The old 'UniFi Controller' plugin appears to be installed"
    echo "<ERROR> (found /etc/systemd/system/unifi.service). Two controllers cannot"
    echo "<ERROR> run side by side (port 8443 conflict). Please uninstall the old"
    echo "<ERROR> plugin first, then install UniFi Controller NG."
    exit 2
fi
echo "<OK> No conflicting UniFi Controller plugin found"

exit 0
