#!/bin/bash
# Creates a timestamped backup of volumes/ and .env.
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-backups}"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
ARCHIVE="$BACKUP_DIR/$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "Stopping stack before backup..."
make -s down 2>/dev/null || true

echo "Creating backup: $ARCHIVE"
tar -czf "$ARCHIVE" \
    --exclude='volumes/*/proc' \
    --exclude='volumes/*/sys' \
    ${VOLUMES_EXTRA:-} \
    volumes/ \
    $([ -f .env ] && echo ".env" || echo "")

SIZE=$(du -sh "$ARCHIVE" | cut -f1)
echo "✓ Backup complete: $ARCHIVE ($SIZE)"
echo ""
echo "To restore: make restore BACKUP=$ARCHIVE"
echo "To restart:  make up"
