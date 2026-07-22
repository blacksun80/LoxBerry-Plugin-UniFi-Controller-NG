#!/bin/bash

# preroot.sh - runs as ROOT, first installation step (also runs on updates,
# before the old plugin folder is deleted).

# Stop the service before the plugin folder (which holds the compose file) is
# removed on update. No-op on a fresh install where the service does not exist.
systemctl stop unifing 2>/dev/null

exit 0
