#!/bin/sh
# Prepare the Railway volume (mounted as root) and start Grafana as its own user.
set -eu

if [ -z "${GF_SECURITY_ADMIN_PASSWORD:-}" ]; then
  echo "FATAL: GF_SECURITY_ADMIN_PASSWORD is empty; refusing to start Grafana with the default admin password." >&2
  exit 1
fi

export GF_SERVER_HTTP_PORT="${PORT:-3000}"
if [ -z "${GF_SERVER_ROOT_URL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export GF_SERVER_ROOT_URL="https://${RAILWAY_PUBLIC_DOMAIN}/"
fi

mkdir -p "$GF_PATHS_DATA" "$GF_PATHS_PLUGINS"
chown -R 472:0 "$GF_PATHS_DATA"

exec setpriv --reuid=472 --regid=0 --clear-groups /run.sh
