#!/bin/bash
# Installs StandaloneCoders Cloud on a fresh server, or switches an existing Coolify server to it.
# Projects, databases, servers and settings are kept. Run as root:
#
#   curl -fsSL https://raw.githubusercontent.com/Roastcoder/standalonecoders-cloud-install/main/install.sh -o install.sh
#   GH_USER="<username you were given>" GH_TOKEN="<access token you were given>" bash install.sh
#
# Set FORCE=1 to switch even when the installed Coolify is newer than StandaloneCoders Cloud.
set -euo pipefail

IMAGE="ghcr.io/roastcoder/standalonecoders-cloud:latest"
RAW="https://raw.githubusercontent.com/Roastcoder/standalonecoders-cloud-install/main"
SOURCE_DIR=/data/coolify/source
BACKUP_DIR=/data/coolify/backups/before-standalonecoders

say() { printf '\n==> %s\n' "$*"; }
fail() { printf '\nError: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || fail "Run this as root, for example: sudo -E bash install.sh"
[ -n "${GH_USER:-}" ] && [ -n "${GH_TOKEN:-}" ] || fail "Set GH_USER and GH_TOKEN to the access details you were given. See the README."
command -v curl >/dev/null || fail "curl is missing. Install it first: apt-get install -y curl"

# 1. Fresh server: install the base platform (Docker, database, proxy) with the official installer.
if [ ! -f "$SOURCE_DIR/docker-compose.yml" ]; then
    say "No existing installation found. Installing the base platform first (takes a few minutes)."
    curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
    EXISTING=0
else
    EXISTING=1
fi
command -v docker >/dev/null || fail "Docker is not installed. The base installation did not finish."

# 2. Log in to the image registry. Docker keeps the login, so later updates work without the token.
say "Logging in to ghcr.io as $GH_USER"
echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin >/dev/null \
    || fail "Login failed. Check GH_USER and GH_TOKEN, and that the token has the read:packages permission."

say "Downloading StandaloneCoders Cloud"
docker pull "$IMAGE" >/dev/null || fail "Could not download $IMAGE. Your token may not have access to it yet."

# 3. Existing server: refuse to go back in version, and back up first.
if [ "$EXISTING" = 1 ]; then
    CURRENT_IMAGE=$(docker inspect coolify --format '{{.Config.Image}}' 2>/dev/null || true)
    CURRENT=${CURRENT_IMAGE##*:}
    OURS=$(docker image inspect "$IMAGE" --format '{{ index .Config.Labels "org.opencontainers.image.version" }}' 2>/dev/null || true)
    case "$CURRENT_IMAGE" in
        *roastcoder*) say "StandaloneCoders Cloud is already installed. Updating it." ;;
        *)
            say "Found Coolify ${CURRENT:-unknown}. StandaloneCoders Cloud is version ${OURS:-unknown}."
            if [ -n "$CURRENT" ] && [ -n "$OURS" ] && [ "$CURRENT" != latest ] \
                && [ "$(printf '%s\n%s\n' "$CURRENT" "$OURS" | sort -V | tail -1)" != "$OURS" ] && [ "${FORCE:-0}" != 1 ]; then
                fail "Your Coolify ($CURRENT) is newer than StandaloneCoders Cloud ($OURS). Switching now would move the database back in version. Wait for the next StandaloneCoders release, or run again with FORCE=1 if you accept the risk."
            fi
            ;;
    esac

    say "Backing up the database and settings to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    STAMP=$(date -u +%Y%m%d-%H%M%S)
    docker exec coolify-db sh -c 'pg_dump -U "$POSTGRES_USER" -d "${POSTGRES_DB:-coolify}"' > "$BACKUP_DIR/database-$STAMP.sql" \
        || fail "The database backup failed, so nothing was changed."
    cp "$SOURCE_DIR/.env" "$BACKUP_DIR/env-$STAMP"
    chmod 600 "$BACKUP_DIR/env-$STAMP" "$BACKUP_DIR/database-$STAMP.sql"
    echo "Backup: $BACKUP_DIR/database-$STAMP.sql"
fi

# 4. Point the panel at our image. The official updater also reads this file, so the switch survives its upgrades.
say "Switching the panel to StandaloneCoders Cloud"
curl -fsSL "$RAW/docker-compose.custom.yml" -o "$SOURCE_DIR/docker-compose.custom.yml"
curl -fsSL "$RAW/update.sh" -o "$SOURCE_DIR/update-custom.sh"
chmod +x "$SOURCE_DIR/update-custom.sh"
bash "$SOURCE_DIR/update-custom.sh"

IP=$(curl -fsS4 --max-time 5 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
cat <<EOF

=================================================================
 StandaloneCoders Cloud is running.
 Open http://${IP}:8000 (or your panel domain) in your browser.
 New versions appear under Settings > Updates.
=================================================================
EOF
