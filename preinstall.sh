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

exit 0
