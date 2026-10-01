#!/bin/bash

set -e

BACKUP_FILE="$1"
RESTORE_DB="hotel_booking_restore"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: ./scripts/restore.sh <backup_file>"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

docker exec -i hotel-postgres psql \
  -U admin \
  -d postgres \
  -c "DROP DATABASE IF EXISTS $RESTORE_DB;"

docker exec -i hotel-postgres psql \
  -U admin \
  -d postgres \
  -c "CREATE DATABASE $RESTORE_DB;"

cat "$BACKUP_FILE" | docker exec -i hotel-postgres \
  psql -U admin -d "$RESTORE_DB"

echo "Restore completed: $RESTORE_DB"
