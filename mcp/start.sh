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
GRAFANA_URL="${GRAFANA_URL%/}"

# Credentials for Grafana:
# 1. GRAFANA_SERVICE_ACCOUNT_TOKEN if you set one (Grafana Cloud or another instance).
# 2. Otherwise, with GRAFANA_USERNAME/GRAFANA_PASSWORD (the bundled Grafana's admin),
#    create a service account "mcp-grafana" once and a fresh token on every boot,
#    so tool calls don't depend on the admin password (and a locked-out admin
#    login can't break the MCP server).
# 3. If that fails, fall back to basic auth with the admin login.
bootstrap_token() {
  role="${MCP_SERVICE_ACCOUNT_ROLE:-Admin}"
  i=0
  until curl -fsS -m 5 "$GRAFANA_URL/api/health" >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge "${MCP_GRAFANA_WAIT:-45}" ]; then
      echo "WARN: Grafana at $GRAFANA_URL did not answer /api/health; using basic auth." >&2
      return 1
    fi
    sleep 2
  done
  api() { curl -fsS -m 15 -u "$GRAFANA_USERNAME:$GRAFANA_PASSWORD" -H 'Content-Type: application/json' "$@"; }
  sa_id=$(api "$GRAFANA_URL/api/serviceaccounts/search?query=mcp-grafana" | jq -r '[.serviceAccounts[] | select(.name=="mcp-grafana")][0].id // empty') || return 1
  if [ -z "$sa_id" ]; then
    sa_id=$(api -X POST "$GRAFANA_URL/api/serviceaccounts" -d "{\"name\":\"mcp-grafana\",\"role\":\"$role\"}" | jq -r '.id // empty') || return 1
    echo "Created Grafana service account mcp-grafana (id $sa_id, role $role)"
  fi
  [ -n "$sa_id" ] || return 1
  for old in $(api "$GRAFANA_URL/api/serviceaccounts/$sa_id/tokens" | jq -r '.[] | select(.name | startswith("railway-mcp-")) | .id'); do
    api -X DELETE "$GRAFANA_URL/api/serviceaccounts/$sa_id/tokens/$old" >/dev/null || true
  done
  key=$(api -X POST "$GRAFANA_URL/api/serviceaccounts/$sa_id/tokens" -d "{\"name\":\"railway-mcp-$(date +%s)\"}" | jq -r '.key // empty') || return 1
  [ -n "$key" ] || return 1
  export GRAFANA_SERVICE_ACCOUNT_TOKEN="$key"
  echo "Using a fresh token for Grafana service account mcp-grafana"
}

if [ -z "${GRAFANA_SERVICE_ACCOUNT_TOKEN:-}" ] && [ -n "${GRAFANA_USERNAME:-}" ] && [ -n "${GRAFANA_PASSWORD:-}" ]; then
  bootstrap_token || echo "WARN: service-account bootstrap failed; using basic auth as ${GRAFANA_USERNAME}." >&2
fi
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
