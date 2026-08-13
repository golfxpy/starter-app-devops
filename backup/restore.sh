#!/bin/sh
set -eu

usage() {
  echo "Usage: restore.sh /backups/<archive>.dump.enc <new_database_name>" >&2
  exit 2
}

[ "$#" -eq 2 ] || usage

archive="$1"
target_database="$2"
password_file="${PGPASSWORD_FILE:-/run/secrets/postgres_password}"
encryption_file="${BACKUP_ENCRYPTION_PASSPHRASE_FILE:-/run/secrets/backup_encryption_passphrase}"

: "${PGHOST:=db}"
: "${PGPORT:=5432}"
: "${PGDATABASE:=psu_activities}"
: "${PGUSER:=app_user}"

case "$target_database" in
  ''|*[!a-zA-Z0-9_]*)
    echo "Target database name may contain only letters, numbers, and underscores" >&2
    exit 2
    ;;
esac

if [ "$target_database" = "$PGDATABASE" ] && [ "${ALLOW_IN_PLACE_RESTORE:-false}" != "true" ]; then
  echo "Refusing to restore over the source database. Choose a new database name." >&2
  exit 2
fi

for required_file in "$archive" "${archive}.sha256" "$password_file" "$encryption_file"; do
  if [ ! -r "$required_file" ]; then
    echo "Required file is not readable: $required_file" >&2
    exit 1
  fi
done

archive_dir="$(dirname "$archive")"
archive_name="$(basename "$archive")"
(cd "$archive_dir" && sha256sum -c "${archive_name}.sha256")

umask 077
plain_file="$(mktemp /tmp/starter-restore.XXXXXX)"
database_created=0

cleanup() {
  status=$?
  rm -f "$plain_file"
  if [ "$status" -ne 0 ] && [ "$database_created" -eq 1 ]; then
    dropdb --if-exists --host="$PGHOST" --port="$PGPORT" --username="$PGUSER" "$target_database" || true
  fi
  trap - EXIT INT TERM
  exit "$status"
}
trap cleanup EXIT INT TERM

PGPASSWORD="$(cat "$password_file")"
export PGPASSWORD

existing="$(psql --host="$PGHOST" --port="$PGPORT" --username="$PGUSER" --dbname=postgres \
  --tuples-only --no-align --command="SELECT 1 FROM pg_database WHERE datname = '$target_database'")"
if [ "$existing" = "1" ]; then
  echo "Target database already exists: $target_database" >&2
  exit 1
fi

openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -pass "file:$encryption_file" \
  -in "$archive" \
  -out "$plain_file"

pg_restore --list "$plain_file" >/dev/null
createdb --host="$PGHOST" --port="$PGPORT" --username="$PGUSER" "$target_database"
database_created=1

pg_restore \
  --host="$PGHOST" \
  --port="$PGPORT" \
  --username="$PGUSER" \
  --dbname="$target_database" \
  --exit-on-error \
  --no-owner \
  --no-privileges \
  "$plain_file"

database_created=0
echo "Restore completed into database: $target_database"
