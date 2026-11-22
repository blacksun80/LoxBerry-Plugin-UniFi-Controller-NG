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

# Laedt das Abbild eines Dienstes, falls es fehlt, und meldet den Fortschritt je Schicht.
pull_with_progress() {
    local SVC=$1 IMAGE LINE ID STATUS BEFORE RC=1 ERRLINE="" LAST=$SECONDS
    local -A SEEN=() DOWNLOADED=() EXTRACTED=()

    IMAGE=$(docker compose config --images "$SVC" 2>/dev/null)
    if [ -n "$IMAGE" ] && docker image inspect "$IMAGE" >/dev/null 2>&1; then
        echo "<OK> Image already present: $IMAGE"
        return 0
    fi
    echo "<INFO> Downloading image ${IMAGE:-$SVC} - this can take several minutes."

    while true; do
        if IFS= read -r -t 30 LINE; then
            case "$LINE" in
                __RC=*) RC=${LINE#__RC=}; break ;;
            esac
            read -r ID STATUS <<< "$LINE"
            if [[ $ID =~ ^[0-9a-f]{12}$ ]]; then
                # Nur angekuendigte Schichten zaehlen, keine Konfigurations-Objekte.
                case "$STATUS" in
                    "Pulling fs layer"*|"Already exists"*) SEEN[$ID]=1 ;;
                esac
                BEFORE="${#DOWNLOADED[@]}/${#EXTRACTED[@]}"
                if [ -n "${SEEN[$ID]}" ]; then
                    case "$STATUS" in
                        "Download complete"*) DOWNLOADED[$ID]=1 ;;
                        "Pull complete"*|"Already exists"*) DOWNLOADED[$ID]=1; EXTRACTED[$ID]=1 ;;
                    esac
                fi
                if [ "$BEFORE" != "${#DOWNLOADED[@]}/${#EXTRACTED[@]}" ]; then
                    echo "<INFO>   Layers downloaded ${#DOWNLOADED[@]}/${#SEEN[@]}, extracted ${#EXTRACTED[@]}/${#SEEN[@]}"
                    LAST=$SECONDS
                fi
            elif [[ ${LINE,,} == *error* ]]; then
                ERRLINE=$LINE
            fi
        elif [ $? -le 128 ]; then
            break
        fi
        if [ $((SECONDS - LAST)) -ge 30 ]; then
            echo "<INFO>   ... still working (downloaded ${#DOWNLOADED[@]}/${#SEEN[@]}, extracted ${#EXTRACTED[@]}/${#SEEN[@]} layers)"
            LAST=$SECONDS
        fi
    done < <(docker compose $PROGRESS pull --policy missing "$SVC" 2>&1; PULL_RC=$?; echo; echo "__RC=$PULL_RC")

    if [ "$RC" = "0" ]; then
        echo "<OK> Image ready: ${IMAGE:-$SVC}"
    else
        echo "<WARNING> Could not download ${IMAGE:-$SVC}: ${ERRLINE:-unknown error}"
        echo "<WARNING> Starting with the local image if one exists."
    fi
}

cd "$PDATA/docker" || exit 2
PROGRESS=""
docker compose --progress plain version >/dev/null 2>&1 && PROGRESS="--progress plain"
pull_with_progress unifing-db
pull_with_progress unifing-app

echo "<INFO> Starting containers"
systemctl restart unifing
echo "<OK> Containers started."

exit 0
