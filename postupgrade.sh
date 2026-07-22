#!/bin/bash

# postupgrade.sh - runs as user loxberry on updates only, after postinstall.sh.

PDIR=$3
PCONFIG=$LBPCONFIG/$PDIR

# Restore the version + MongoDB password saved by preupgrade.sh.
if [ -f /tmp/unifing_env.bak ]; then
    mkdir -p "$PCONFIG"
    cp /tmp/unifing_env.bak "$PCONFIG/env"
    rm -f /tmp/unifing_env.bak
    echo "<OK> Restored plugin env from before the update"
fi

exit 0
