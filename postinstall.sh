#!/bin/bash

# postinstall.sh - runs as user loxberry after the plugin files are copied.

PDIR=$3
PCONFIG=$LBPCONFIG/$PDIR

# The app container reads PUID/PGID from this env_file so its mounted config is
# owned by the loxberry user.
mkdir -p "$PCONFIG"
echo "PUID=$(id -u)" > "$PCONFIG/unifi.env"
echo "PGID=$(id -g)" >> "$PCONFIG/unifi.env"
echo "<OK> Wrote container user env"

exit 0
