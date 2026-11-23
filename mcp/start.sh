#!/bin/sh
# Start mcp-grafana in streamable-HTTP mode on $PORT for Railway.
set -eu

if [ -z "${MCP_GRAFANA_SERVER_TOKEN:-}" ]; then
  echo "FATAL: MCP_GRAFANA_SERVER_TOKEN is empty. Set it to a long random value; MCP clients send it as 'Authorization: Bearer <token>'." >&2
  exit 1
fi
if [ -z "${GRAFANA_URL:-}" ]; then
  echo "FATAL: GRAFANA_URL is empty. Point it at your Grafana (the bundled one is http://grafana.railway.internal:3000)." >&2
  exit 1
fi

# An explicit service account token wins over the bundled Grafana's admin login
# (useful when GRAFANA_URL points at Grafana Cloud or another instance).
if [ -n "${GRAFANA_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  unset GRAFANA_USERNAME GRAFANA_PASSWORD
fi

set -- /app/mcp-grafana \
  --transport streamable-http \
  --address ":${PORT:-8000}" \
  --endpoint-path /mcp \
  --allowed-hosts "${MCP_ALLOWED_HOSTS:-*}" \
  --log-level "${MCP_LOG_LEVEL:-info}"

if [ -n "${MCP_ALLOWED_ORIGINS:-}" ]; then
  set -- "$@" --allowed-origins "$MCP_ALLOWED_ORIGINS"
fi
if [ "${MCP_READ_ONLY:-false}" = "true" ]; then
  set -- "$@" --disable-write
fi
if [ -n "${MCP_ENABLED_TOOLS:-}" ]; then
  set -- "$@" --enabled-tools "$MCP_ENABLED_TOOLS"
fi

echo "Starting mcp-grafana on :${PORT:-8000}/mcp (Grafana: ${GRAFANA_URL}, read-only: ${MCP_READ_ONLY:-false})"
exec "$@"
