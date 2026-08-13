#!/bin/sh
set -eu

if [ -n "${PGPASSWORD_FILE:-}" ]; then
  if [ ! -r "$PGPASSWORD_FILE" ]; then
    echo "PGPASSWORD_FILE is not readable: $PGPASSWORD_FILE" >&2
    exit 1
  fi
  PGPASSWORD="$(cat "$PGPASSWORD_FILE")"
  export PGPASSWORD
fi

exec "$@"
