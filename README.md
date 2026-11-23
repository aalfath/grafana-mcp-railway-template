[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/grafana-mcp-1?utm_medium=integration&utm_source=button&utm_campaign=grafana-mcp)

# Grafana MCP on Railway

One-click Railway template for [Grafana MCP](https://github.com/grafana/mcp-grafana), Grafana Labs' official Model Context Protocol server, together with a Grafana instance for it to work on. AI assistants (Claude, Cursor, VS Code, Windsurf…) connect to one bearer-token-protected HTTP endpoint and get about 80 Grafana tools: dashboards, Prometheus and Loki queries, alert rules, datasources, incidents and more.

## What it deploys

| Service | Folder | Version | What it does |
|---|---|---|---|
| **Grafana** | `grafana/` | Grafana OSS `13.3.1` (`grafana/grafana@sha256:0615ec4f…`) | Dashboards and datasources. Data, plugins and the SQLite database live on a Railway volume at `/var/lib/grafana`. Public domain, health check `/api/health`. |
| **Grafana MCP** | `mcp/` | mcp-grafana `2.3.0` (`grafana/mcp-grafana@sha256:c27248b5…`) | MCP server in streamable-HTTP mode at `https://YOUR-MCP-DOMAIN/mcp`, health check `/healthz`. Requires `Authorization: Bearer $MCP_GRAFANA_SERVER_TOKEN`. Stateless. |

Each folder has a `Dockerfile` that starts `FROM` the official image pinned by version **and** digest, plus a small `start.sh`.

## Variables

Nothing to fill in. Everything is generated or derived:

| Service | Variable | Default | Purpose |
|---|---|---|---|
| Grafana | `GF_SECURITY_ADMIN_USER` | `admin` | Grafana admin user name |
| Grafana | `GF_SECURITY_ADMIN_PASSWORD` | `${{secret(24)}}` | Grafana admin password (Grafana refuses to start without one) |
| Grafana | `PORT` | `3000` | Grafana HTTP port |
| Grafana MCP | `MCP_GRAFANA_SERVER_TOKEN` | `${{secret(48)}}` | Bearer token every MCP client must send |
| Grafana MCP | `GRAFANA_URL` | `http://${{Grafana.RAILWAY_PRIVATE_DOMAIN}}:${{Grafana.PORT}}` | Grafana over the private network |
| Grafana MCP | `GRAFANA_USERNAME` / `GRAFANA_PASSWORD` | references to the Grafana admin | Used once per boot to create the `mcp-grafana` service account and mint a fresh token for it; tool calls use that token |
| Grafana MCP | `PORT` | `8000` | MCP HTTP port |

Optional, add them on the **Grafana MCP** service if you need them:

- `MCP_READ_ONLY=true`: removes every write tool (`--disable-write`).
- `MCP_ENABLED_TOOLS=search,datasource,prometheus,loki,dashboard`: pick tool categories.
- `GRAFANA_SERVICE_ACCOUNT_TOKEN` + `GRAFANA_URL`: use your own Grafana or Grafana Cloud instead of the bundled one (delete `GRAFANA_USERNAME`/`GRAFANA_PASSWORD`, then you can remove the Grafana service).
- `MCP_SERVICE_ACCOUNT_ROLE=Editor` or `Viewer`: role of the auto-created service account (default `Admin`; applies when the account is first created).
- `MCP_ALLOWED_ORIGINS`: allow browser-based MCP clients from these origins (none by default).

## Connect a client

Copy the token from the Grafana MCP service's **Variables** tab.

```sh
claude mcp add --transport http grafana https://YOUR-MCP-DOMAIN/mcp --header "Authorization: Bearer YOUR-MCP-TOKEN"
```

```json
{
  "mcpServers": {
    "grafana": {
      "url": "https://YOUR-MCP-DOMAIN/mcp",
      "headers": { "Authorization": "Bearer YOUR-MCP-TOKEN" }
    }
  }
}
```

## Resources

Both services fit Railway's Free plan (0.5 GB RAM each). Measured on Railway with a 0.5 GB / 1 vCPU limit: Grafana about 260–300 MB anonymous memory, the MCP server about 25 MB. Grafana's Go heap is capped from the container limit (`GOMEMLIMIT`), automatic plugin pre-installs and update checks are off, and the MCP server's anonymous usage statistics are off (`GRAFANA_USAGE_STATS=disabled`). An unexpected stop exits non-zero, so Railway's `ON_FAILURE` restart policy brings it back.

## Updates

Railway shows deployers an "update available" notice when this repo's `main` changes. We bump the pinned versions here and record each change in [`CHANGELOG.md`](CHANGELOG.md), breaking changes first. Read it before you apply an update.

## Local test

```sh
LOCAL_ADMIN_PASSWORD=$(openssl rand -hex 16) LOCAL_MCP_TOKEN=$(openssl rand -hex 32) docker compose up --build
```

## Licences

mcp-grafana is Apache-2.0, Grafana OSS is AGPL-3.0 (unmodified official images). This wrapper is MIT.
