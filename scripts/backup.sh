#!/bin/bash

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups"

mkdir -p "$BACKUP_DIR"

docker exec hotel-postgres pg_dump \
  -U admin \
  -d hotel_booking \
  > "$BACKUP_DIR/hotel_booking_$TIMESTAMP.sql"

echo "Backup created: $BACKUP_DIR/hotel_booking_$TIMESTAMP.sql"