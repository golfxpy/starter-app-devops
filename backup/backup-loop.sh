#!/bin/sh
set -eu

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

interval="${BACKUP_INTERVAL_SECONDS:-86400}"
case "$interval" in
  ''|*[!0-9]*)
    echo "BACKUP_INTERVAL_SECONDS must be a positive integer" >&2
    exit 1
    ;;
esac

if [ "$interval" -lt 300 ]; then
  echo "BACKUP_INTERVAL_SECONDS must be at least 300 seconds" >&2
  exit 1
fi

while true; do
  backup.sh || true
  sleep "$interval"
done
