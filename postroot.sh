#!/bin/bash

# postroot.sh - runs as ROOT, last installation step (after postinstall/postupgrade).

PDIR=$3
PDATA=$LBPDATA/$PDIR
PCONFIG=$LBPCONFIG/$PDIR

# Default container version on a fresh install (kept across updates via the
# env file preserved by pre/postupgrade).
if [ ! -f "$PCONFIG/env" ]; then
    echo "VERSION=latest" > "$PCONFIG/env"
    chown loxberry:loxberry "$PCONFIG/env"
fi

# Generate a random MongoDB password once and keep it across updates.
if ! grep -q '^MONGO_PASS=' "$PCONFIG/env"; then
    echo "<INFO> Generating MongoDB password"
    MONGO_PASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 32)
    if [ ${#MONGO_PASS} -lt 32 ]; then
        echo "<ERROR> Failed to generate a MongoDB password (got ${#MONGO_PASS} chars)."
        exit 2
    fi
    echo "MONGO_PASS=$MONGO_PASS" >> "$PCONFIG/env"
    chown loxberry:loxberry "$PCONFIG/env"
fi

# Write the password into the mongo init script (takes effect only on the first
# database start with an empty volume).
MONGO_PASS=$(grep '^MONGO_PASS=' "$PCONFIG/env" | cut -d '=' -f 2-)
sed -i "s/MONGO_PASS_PLACEHOLDER/$MONGO_PASS/g" "$PDATA/docker/init-mongo.js"

# docker compose reads ${VERSION}/${MONGO_PASS} from the .env in its working dir.
ln -f -s "$PCONFIG/env" "$PDATA/docker/.env"

# Install and (re)start the systemd service.
cp -f "$PDATA/docker/unifing.service" /etc/systemd/system/unifing.service
systemctl daemon-reload
systemctl enable unifing

# 'systemctl restart' blocks until the unit finishes, and unifing.service is
# Type=oneshot running 'docker compose up -d' - so this call waits for BOTH
# images (UniFi Network Application + MongoDB, several hundred MB combined)
# to be pulled AND both containers to start before returning. Nothing is
# echoed to the install log during that time, which looks like a hang rather
# than a normal image download - especially on a Raspberry Pi's slower
# storage/network. This step alone took 1m25s pulling fresh images during
# testing; a few minutes on a slow connection is expected, not broken.
echo "<INFO> Pulling Docker images and starting containers - first run only,"
echo "<INFO> can take several minutes depending on your internet connection."
systemctl restart unifing
echo "<OK> Containers started."

exit 0
