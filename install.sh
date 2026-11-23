#!/bin/bash
# Installs StandaloneCoders Cloud on a fresh server, or switches an existing Coolify server to it.
# Projects, databases, servers and settings are kept. Run as root:
#
#   curl -fsSL https://raw.githubusercontent.com/Roastcoder/standalonecoders-cloud-install/main/install.sh | bash
#
# Set FORCE=1 to switch even when the installed Coolify is newer than StandaloneCoders Cloud.
set -euo pipefail

IMAGE="ghcr.io/roastcoder/standalonecoders-cloud:latest"
RAW="https://raw.githubusercontent.com/Roastcoder/standalonecoders-cloud-install/main"
SOURCE_DIR=/data/coolify/source
BACKUP_DIR=/data/coolify/backups/before-standalonecoders

LOG=/tmp/standalonecoders-install.log
: > "$LOG"
if [ -t 1 ]; then G=$'\e[38;5;155m'; D=$'\e[2m'; R=$'\e[31m'; B=$'\e[1m'; N=$'\e[0m'; else G= D= R= B= N=; fi
STEP=0; TOTAL=4

banner() {
    printf '%s\n' "$G" \
'  ███████╗ ██████╗    ██████╗██╗      ██████╗ ██╗   ██╗██████╗' \
'  ██╔════╝██╔════╝   ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗' \
'  ███████╗██║        ██║     ██║     ██║   ██║██║   ██║██║  ██║' \
'  ╚════██║██║        ██║     ██║     ██║   ██║██║   ██║██║  ██║' \
'  ███████║╚██████╗   ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝' \
'  ╚══════╝ ╚═════╝    ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝'
    printf '%s  StandaloneCoders Cloud installer   mail · WhatsApp AI · safe updates%s\n\n' "$D" "$N"
}
say() { STEP=$((STEP + 1)); printf '\n%s[%d/%d]%s %s%s%s\n' "$G" "$STEP" "$TOTAL" "$N" "$B" "$*" "$N"; }
info() { printf '      %s%s%s\n' "$D" "$*" "$N"; }
fail() { printf '\n%s✗ %s%s\n' "$R" "$*" "$N" >&2; exit 1; }

# Runs a command with a spinner. Output goes to $LOG and its tail is shown if the command fails.
run() {
    local label=$1; shift
    "$@" >>"$LOG" 2>&1 &
    local pid=$! i=0 frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 "$pid" 2>/dev/null; do
        [ -t 1 ] && printf '\r      %s%s%s %s' "$G" "${frames:i++%10:1}" "$N" "$label"
        sleep 0.1
    done
    if wait "$pid"; then
        printf '\r      %s✓%s %s\n' "$G" "$N" "$label"
    else
        printf '\r      %s✗%s %s\n' "$R" "$N" "$label"
        tail -n 15 "$LOG" | sed 's/^/        /'
        return 1
    fi
}

banner
[ "$(id -u)" = 0 ] || fail "Run this as root, for example: sudo -E bash install.sh"
command -v curl >/dev/null || fail "curl is missing. Install it first: apt-get install -y curl"

# 1. Fresh server: install the base platform (Docker, database, proxy) with the official installer.
if [ ! -f "$SOURCE_DIR/docker-compose.yml" ]; then
    say "Installing the base platform"
    info "No existing installation found. This takes a few minutes."
    run "Docker, database and proxy" bash -c 'curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash' \
        || fail "The base installation failed. Full log: $LOG"
    EXISTING=0
else
    say "Checking the existing installation"
    info "Found an installation in $SOURCE_DIR. Your projects and data stay."
    EXISTING=1
fi
command -v docker >/dev/null || fail "Docker is not installed. The base installation did not finish."

# 2. The image is public, so no registry login is needed.
say "Downloading StandaloneCoders Cloud"
run "Pulling the image" docker pull "$IMAGE" || fail "Could not download $IMAGE. Check the server's internet connection. Full log: $LOG"

# 3. Existing server: refuse to go back in version, and back up first.
if [ "$EXISTING" = 1 ]; then
    CURRENT_IMAGE=$(docker inspect coolify --format '{{.Config.Image}}' 2>/dev/null || true)
    CURRENT=${CURRENT_IMAGE##*:}
    OURS=$(docker image inspect "$IMAGE" --format '{{ index .Config.Labels "org.opencontainers.image.version" }}' 2>/dev/null || true)
    case "$CURRENT_IMAGE" in
        *roastcoder*) info "StandaloneCoders Cloud is already installed. Updating it." ;;
        *)
            info "Found Coolify ${CURRENT:-unknown}. StandaloneCoders Cloud is version ${OURS:-unknown}."
            if [ -n "$CURRENT" ] && [ -n "$OURS" ] && [ "$CURRENT" != latest ] \
                && [ "$(printf '%s\n%s\n' "$CURRENT" "$OURS" | sort -V | tail -1)" != "$OURS" ] && [ "${FORCE:-0}" != 1 ]; then
                fail "Your Coolify ($CURRENT) is newer than StandaloneCoders Cloud ($OURS). Switching now would move the database back in version. Wait for the next StandaloneCoders release, or run again with FORCE=1 if you accept the risk."
            fi
            ;;
    esac

    say "Backing up your data"
    mkdir -p "$BACKUP_DIR"
    STAMP=$(date -u +%Y%m%d-%H%M%S)
    backup_db() { docker exec coolify-db sh -c 'pg_dump -U "$POSTGRES_USER" -d "${POSTGRES_DB:-coolify}"' > "$BACKUP_DIR/database-$STAMP.sql"; }
    run "Database" backup_db \
        || fail "The database backup failed, so nothing was changed."
    cp "$SOURCE_DIR/.env" "$BACKUP_DIR/env-$STAMP"
    chmod 600 "$BACKUP_DIR/env-$STAMP" "$BACKUP_DIR/database-$STAMP.sql"
    info "Saved to $BACKUP_DIR/database-$STAMP.sql"
else
    say "Backing up your data"
    info "Fresh server, nothing to back up."
fi

# 4. Point the panel at our image. The official updater also reads this file, so the switch survives its upgrades.
say "Switching the panel to StandaloneCoders Cloud"
fetch_files() {
    curl -fsSL "$RAW/docker-compose.custom.yml" -o "$SOURCE_DIR/docker-compose.custom.yml" \
        && curl -fsSL "$RAW/update.sh" -o "$SOURCE_DIR/update-custom.sh"
}
run "Downloading the settings" fetch_files \
    || fail "Could not download the settings files. Full log: $LOG"
chmod +x "$SOURCE_DIR/update-custom.sh"
run "Restarting the panel (about a minute; your apps keep running)" bash "$SOURCE_DIR/update-custom.sh" \
    || fail "The panel did not start. Full log: $LOG"

IP=$(curl -fsS4 --max-time 5 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
printf '\n%s  ┃%s %s✓ StandaloneCoders Cloud is running%s\n' "$G" "$N" "$B" "$N"
printf '%s  ┃%s Open    http://%s:8000 (or your panel domain)\n' "$G" "$N" "$IP"
printf '%s  ┃%s Update  Settings → Updates in the panel\n' "$G" "$N"
printf '%s  ┃%s Log     %s\n\n' "$G" "$N" "$LOG"
