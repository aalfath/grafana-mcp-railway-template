# Deploy and Host Grafana MCP on Railway

Grafana MCP is Grafana Labs' official Model Context Protocol server. It lets AI assistants such as Claude, Cursor or VS Code Copilot search dashboards, query Prometheus and Loki, read and edit alert rules, inspect datasources and create dashboards in Grafana, through about 80 tools, over one authenticated HTTP endpoint.

## About Hosting Grafana MCP

This template deploys two services from one public GitHub repo. **Grafana** 13.3.1 (OSS) keeps its database, dashboards and plugins on a Railway volume and gets a generated admin password. **Grafana MCP** 2.3.0 runs in streamable-HTTP mode on its own public domain at `/mcp`, and rejects every request without the generated bearer token. On boot it creates a Grafana service account called `mcp-grafana` and uses a fresh token for it, so you never paste a Grafana key. Both images are pinned by version and digest; merges to the repo reach you as Railway update notices. Nothing to fill in at deploy time.

## Common Use Cases

* Ask an AI assistant "why did errors spike at 14:00?" and let it query Prometheus, Loki and your dashboards for the answer
* Have an agent build or update Grafana dashboards and alert rules from a plain-language description
* Give a team's coding assistants one shared, token-protected Grafana tool endpoint

## Dependencies for Grafana MCP Hosting

* Grafana (included, with a volume), or your own Grafana or Grafana Cloud instance
* An MCP client that supports remote HTTP servers with a custom header (Claude Code, Claude Desktop through `mcp-remote`, Cursor, VS Code, Windsurf)

### Deployment Dependencies

* [grafana/mcp-grafana v2.3.0](https://github.com/grafana/mcp-grafana/releases/tag/v2.3.0) (Apache-2.0)
* [Grafana OSS 13.3.1](https://github.com/grafana/grafana/releases/tag/v13.3.1) (AGPL-3.0)
* Template repo: [aalfath/grafana-mcp-railway-template](https://github.com/aalfath/grafana-mcp-railway-template)

### Implementation Details

**After deploy**

1. Open the **Grafana** service's domain and sign in as `admin` with `GF_SECURITY_ADMIN_PASSWORD` from the Grafana service's Variables tab. Add your datasources (Prometheus, Loki, Postgres and so on).
2. Copy `MCP_GRAFANA_SERVER_TOKEN` from the **Grafana MCP** service's Variables tab and its domain, then add the server to your client.

Claude Code:

```sh
claude mcp add --transport http grafana https://YOUR-MCP-DOMAIN/mcp --header "Authorization: Bearer YOUR-MCP-TOKEN"
```

Cursor, VS Code and other JSON configs:

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

**Options** (Grafana MCP service variables): `MCP_READ_ONLY=true` removes every write tool. To use your own Grafana or Grafana Cloud instead of the bundled one, set `GRAFANA_URL` and `GRAFANA_SERVICE_ACCOUNT_TOKEN`, delete `GRAFANA_USERNAME` and `GRAFANA_PASSWORD`, then remove the Grafana service. `MCP_ENABLED_TOOLS` picks tool categories (for example `search,datasource,prometheus,loki,dashboard`). The service account gets the Admin role by default (`MCP_SERVICE_ACCOUNT_ROLE=Editor` or `Viewer` narrows it on a fresh deploy).

**Resources:** fits Railway's Free plan (0.5 GB per service): Grafana used about 260–300 MB, the MCP server about 25 MB in our tests. Anonymous usage statistics to Grafana Labs are off.

**Updates:** we bump both pinned versions in the repo; Railway then shows an "update available" notice on your project, and `CHANGELOG.md` lists what changed.

## Why Deploy Grafana MCP on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Grafana MCP on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
