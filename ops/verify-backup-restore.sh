#!/bin/sh
set -eu

backup_dir="${BACKUP_DIR:-./backups}"
target_database="restore_verify_$(date +%s)"
source_database="${PGDATABASE:-psu_activities}"
database_user="${PGUSER:-app_user}"

case "$target_database" in
  restore_verify_[0-9]*) ;;
  *)
    echo "Unsafe generated target database name: $target_database" >&2
    exit 1
    ;;
esac

cleanup() {
  docker compose exec -T db dropdb --if-exists --username="$database_user" "$target_database" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

docker compose --profile backup run --rm backup backup.sh

archive="$(find "$backup_dir" -maxdepth 1 -type f -name '*.dump.enc' | sort | tail -n 1)"
if [ -z "$archive" ]; then
  echo "No encrypted backup archive was created in $backup_dir" >&2
  exit 1
fi

archive_name="$(basename "$archive")"
MSYS_NO_PATHCONV=1 docker compose --profile backup run --rm backup \
  restore.sh "/backups/$archive_name" "$target_database"

count_query="SELECT (SELECT COUNT(*) FROM activities)::text || ':' || (SELECT COUNT(*) FROM registrations)::text;"
source_counts="$(docker compose exec -T db psql --username="$database_user" --dbname="$source_database" \
  --tuples-only --no-align --command="$count_query")"
target_counts="$(docker compose exec -T db psql --username="$database_user" --dbname="$target_database" \
  --tuples-only --no-align --command="$count_query")"

if [ "$source_counts" != "$target_counts" ]; then
  echo "Restore verification failed: source=$source_counts target=$target_counts" >&2
  exit 1
fi

echo "Backup/restore verification passed: activities:registrations=$target_counts"
