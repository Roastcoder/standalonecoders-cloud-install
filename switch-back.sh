#!/bin/bash
# Switches the server back to the official Coolify release. Projects, databases and settings are kept. Run as root:
#   curl -fsSL https://raw.githubusercontent.com/Roastcoder/standalonecoders-cloud-install/main/switch-back.sh | bash
set -euo pipefail

SOURCE_DIR=/data/coolify/source
[ "$(id -u)" = 0 ] || { echo "Run this as root." >&2; exit 1; }
[ -f "$SOURCE_DIR/docker-compose.custom.yml" ] || { echo "StandaloneCoders Cloud is not installed here."; exit 0; }

mkdir -p /data/coolify/backups/before-switch-back
STAMP=$(date -u +%Y%m%d-%H%M%S)
docker exec coolify-db sh -c 'pg_dump -U "$POSTGRES_USER" -d "${POSTGRES_DB:-coolify}"' > "/data/coolify/backups/before-switch-back/database-$STAMP.sql"
chmod 600 "/data/coolify/backups/before-switch-back/database-$STAMP.sql"
echo "Backup: /data/coolify/backups/before-switch-back/database-$STAMP.sql"

rm -f "$SOURCE_DIR/docker-compose.custom.yml" "$SOURCE_DIR/update-custom.sh" "$SOURCE_DIR/.custom-update-status.json"
# The official installer upgrades an existing installation in place to the newest official release.
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
echo "Switched back to the official Coolify release."
