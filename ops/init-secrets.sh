#!/bin/sh
set -eu

force=0
if [ "${1:-}" = "--force" ]; then
  force=1
elif [ "$#" -gt 0 ]; then
  echo "Usage: sh ops/init-secrets.sh [--force]" >&2
  exit 2
fi

command -v openssl >/dev/null 2>&1 || {
  echo "openssl is required to generate secrets" >&2
  exit 1
}

secret_dir="${SECRET_DIR:-./secrets}"
mkdir -p "$secret_dir"
umask 077

generate_secret() {
  target="$1"
  if [ -e "$target" ] && [ "$force" -ne 1 ]; then
    echo "Keeping existing secret: $target"
    return
  fi
  temporary="${target}.tmp.$$"
  openssl rand -base64 48 > "$temporary"
  chmod 0600 "$temporary"
  mv "$temporary" "$target"
  echo "Generated secret: $target"
}

generate_secret "$secret_dir/postgres_password.txt"
generate_secret "$secret_dir/backup_encryption_passphrase.txt"
