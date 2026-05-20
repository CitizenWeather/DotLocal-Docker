#!/bin/bash
# Restores volumes/ and .env from a backup tarball.
set -euo pipefail

ARCHIVE="${1:-}"

if [ -z "$ARCHIVE" ]; then
    echo "Usage: make restore BACKUP=<path-to-backup.tar.gz>" >&2
    echo ""
    echo "Available backups:"
    ls -lh backups/*.tar.gz 2>/dev/null || echo "  (none found in backups/)"
    exit 1
fi

if [ ! -f "$ARCHIVE" ]; then
    echo "ERROR: backup file not found: $ARCHIVE" >&2
    exit 1
fi

echo "This will REPLACE the current volumes/ directory with the backup."
printf "Continue? [y/N] "
read -r answer
if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    echo "Aborted."
    exit 0
fi

echo "Stopping stack..."
make -s down 2>/dev/null || true

echo "Removing current volumes/..."
rm -rf volumes/

echo "Extracting backup: $ARCHIVE"
tar -xzf "$ARCHIVE"

echo "✓ Restore complete"
echo ""
echo "Run 'make up' to restart the stack."
