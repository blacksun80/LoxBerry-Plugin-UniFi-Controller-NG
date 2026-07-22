#!/bin/bash

# Service control helper for the web frontend. Scripts in sbin/ are granted
# passwordless sudo by the LoxBerry installer, so the frontend can call this as
# root via: sudo <sbindir>/unifing_ctl.sh <action>

case "$1" in
    restart) systemctl restart unifing ;;
    start)   systemctl start unifing ;;
    stop)    systemctl stop unifing ;;
    reset)
        # Force-remove the containers (named volumes/data are kept) and let the
        # service recreate them + the network cleanly.
        docker rm -f unifing-app unifing-db 2>/dev/null
        systemctl restart unifing
        ;;
    *)
        echo "usage: $0 {restart|start|stop|reset}"
        exit 1
        ;;
esac

exit 0
