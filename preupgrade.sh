#!/bin/bash

# preupgrade.sh - runs as user loxberry on updates only, before the old plugin
# folder is deleted.

PDIR=$3
PCONFIG=$LBPCONFIG/$PDIR

# Preserve the generated MongoDB password and the selected version across the
# update. The UniFi config and database live in Docker named volumes and survive
# on their own.
if [ -f "$PCONFIG/env" ]; then
    cp "$PCONFIG/env" /tmp/unifing_env.bak
    echo "<INFO> Saved plugin env (version + MongoDB password) for the update"
fi

exit 0
