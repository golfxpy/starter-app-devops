#!/bin/sh
set -eu

backup_dir="${BACKUP_DIR:-/backups}"
metrics_dir="${METRICS_DIR:-/metrics}"
retention_days="${BACKUP_RETENTION_DAYS:-7}"
password_file="${PGPASSWORD_FILE:-/run/secrets/postgres_password}"
encryption_file="${BACKUP_ENCRYPTION_PASSPHRASE_FILE:-/run/secrets/backup_encryption_passphrase}"

: "${PGHOST:=db}"
: "${PGPORT:=5432}"
: "${PGDATABASE:=psu_activities}"
: "${PGUSER:=app_user}"

case "$retention_days" in
  ''|*[!0-9]*)
    echo "BACKUP_RETENTION_DAYS must be a non-negative integer" >&2
    exit 1
    ;;
esac

for required_file in "$password_file" "$encryption_file"; do
  if [ ! -r "$required_file" ]; then
    echo "Secret file is not readable: $required_file" >&2
    exit 1
  fi
done

mkdir -p "$backup_dir" "$metrics_dir"
umask 077

PGPASSWORD="$(cat "$password_file")"
export PGPASSWORD
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
plain_file="$(mktemp "$backup_dir/.${PGDATABASE}_${timestamp}.XXXXXX")"
encrypted_file="$backup_dir/${PGDATABASE}_${timestamp}.dump.enc"
metric_file="$metrics_dir/starter_backup.prom"
backup_succeeded=0

write_metrics() {
  now="$(date +%s)"
  previous_success="0"
  if [ -r "$metric_file" ]; then
    previous_success="$(awk '/^starter_backup_last_success_timestamp_seconds / { print $2 }' "$metric_file" | tail -n 1)"
    previous_success="${previous_success:-0}"
  fi
  if [ "$backup_succeeded" -eq 1 ]; then
    previous_success="$now"
  fi

  metric_tmp="$(mktemp "$metrics_dir/.starter_backup.XXXXXX")"
  {
    echo '# HELP starter_backup_last_run_success Whether the last PostgreSQL backup completed successfully.'
    echo '# TYPE starter_backup_last_run_success gauge'
    echo "starter_backup_last_run_success $backup_succeeded"
    echo '# HELP starter_backup_last_success_timestamp_seconds Unix timestamp of the last successful backup.'
    echo '# TYPE starter_backup_last_success_timestamp_seconds gauge'
    echo "starter_backup_last_success_timestamp_seconds $previous_success"
  } > "$metric_tmp"
  mv "$metric_tmp" "$metric_file"
  chmod 0644 "$metric_file"
}

cleanup() {
  status=$?
  rm -f "$plain_file"
  write_metrics
  trap - EXIT INT TERM
  exit "$status"
}
trap cleanup EXIT INT TERM

echo "Starting encrypted backup for database $PGDATABASE"
pg_dump \
  --host="$PGHOST" \
  --port="$PGPORT" \
  --username="$PGUSER" \
  --dbname="$PGDATABASE" \
  --format=custom \
  --no-owner \
  --no-privileges \
  --file="$plain_file"

# ตรวจว่า archive เปิดอ่านได้ก่อนเข้ารหัสและประกาศว่าสำเร็จ
pg_restore --list "$plain_file" >/dev/null

openssl enc -aes-256-cbc -salt -pbkdf2 -iter 200000 \
  -pass "file:$encryption_file" \
  -in "$plain_file" \
  -out "$encrypted_file"

checksum="$(sha256sum "$encrypted_file" | awk '{ print $1 }')"
printf '%s  %s\n' "$checksum" "$(basename "$encrypted_file")" > "${encrypted_file}.sha256"

backup_succeeded=1

# ลบเฉพาะ archive/checksum ภายใน backup directory ที่เก่ากว่า retention
find "$backup_dir" -type f \( -name '*.dump.enc' -o -name '*.dump.enc.sha256' \) \
  -mtime "+$retention_days" -delete

echo "Backup completed: $encrypted_file"
