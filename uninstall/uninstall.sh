#!/bin/bash

# uninstall.sh - runs as ROOT when the plugin is uninstalled. The plugin's own
# directories are removed by LoxBerry; clean up what was created outside them.

# Stop and remove the systemd service (its ExecStop runs "docker compose down").
systemctl stop unifing 2>/dev/null
systemctl disable unifing 2>/dev/null
rm -f /etc/systemd/system/unifing.service
systemctl daemon-reload

# Remove the containers (fallback if compose down did not run) and their data
# volumes, then the images to free disk space. Docker refuses to remove an image
# still used by a running container, so a mongo:4.4 shared with another app stays.
docker rm -f unifing-app unifing-db 2>/dev/null
docker volume rm unifing-appdata unifing-dbdata 2>/dev/null

IMAGES=$(docker images 'lscr.io/linuxserver/unifi-network-application' -q; docker images 'mongo:4.4' -q)
IMAGES=$(echo "$IMAGES" | sort -u)
if [ -n "$IMAGES" ]; then
    docker rmi -f $IMAGES 2>/dev/null
fi

# The Docker engine itself is intentionally left untouched (shared, not ours).

exit 0
