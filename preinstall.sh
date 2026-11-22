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

# Speicherplatz im Docker-Datenverzeichnis fuer fehlende Abbilder pruefen.
COMPOSE_FILE="$6/data/docker/docker-compose.yml"
VERSION=latest
if [ -f /tmp/unifing_env.bak ]; then
    SAVED_VERSION=$(grep '^VERSION=' /tmp/unifing_env.bak | cut -d '=' -f 2-)
    [ -n "$SAVED_VERSION" ] && VERSION=$SAVED_VERSION
fi
DOCKER_ROOT=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)
[ -z "$DOCKER_ROOT" ] && DOCKER_ROOT=/var/lib/docker
FREE_MB=$(df -Pm "$DOCKER_ROOT" | awk 'NR==2 {print $4}')

# Bedarf je Abbild in MB (entpackt plus Download), dazu eine feste Reserve.
NEED_MB=600
for IMAGE in $(awk '$1 == "image:" {print $2}' "$COMPOSE_FILE"); do
    IMAGE=${IMAGE//'${VERSION}'/$VERSION}
    if docker image inspect "$IMAGE" >/dev/null 2>&1; then
        echo "<INFO> Image already present: $IMAGE"
        continue
    fi
    case "$IMAGE" in
        *unifi-network-application*) NEED_MB=$((NEED_MB + 1500)) ;;
        *mongo*)                     NEED_MB=$((NEED_MB + 900)) ;;
        *)                           NEED_MB=$((NEED_MB + 1000)) ;;
    esac
done

echo "<INFO> Free disk space in $DOCKER_ROOT: $FREE_MB MB, required: $NEED_MB MB"
if [ "$FREE_MB" -lt "$NEED_MB" ]; then
    echo "<ERROR> Not enough free disk space for the Docker images."
    echo "<ERROR> Required: $NEED_MB MB, available: $FREE_MB MB in $DOCKER_ROOT."
    echo "<ERROR> Please free up disk space (check 'docker system df' for Docker"
    echo "<ERROR> images you no longer need) and install again."
    exit 2
fi
echo "<OK> Enough free disk space for the Docker images"

exit 0
