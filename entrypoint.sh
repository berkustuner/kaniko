#!/bin/sh
set -eu

# DB_PASS_FILE varsa içeriğini DB_PASS'e bas
if [ -n "${DB_PASS_FILE:-}" ] && [ -f "${DB_PASS_FILE}" ]; then
  export DB_PASS="$(tr -d '\r\n' < "${DB_PASS_FILE}")"
fi

# DATABASE_URL yoksa ama DB_* varsa, kendimiz üretelim
if [ -z "${DATABASE_URL:-}" ] && [ -n "${DB_HOST:-}" ] && [ -n "${DB_USER:-}" ] && [ -n "${DB_NAME:-}" ] && [ -n "${DB_PASS:-}" ]; then
  export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"
fi

exec "$@"

