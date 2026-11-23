# Changelog

## 2026-11-23: first release

- Grafana OSS 13.3.1 (`grafana/grafana:13.3.1@sha256:0615ec4fbd4072004b7d86b46ded63013a74b7d6eb1119273dd89e8fa25c13cf`) with its data on a Railway volume and a generated admin password.
- Grafana MCP 2.3.0 (`grafana/mcp-grafana:2.3.0@sha256:c27248b5919d09d64ea273ca1b128b32902c6796f6e2dfcd11849d4f1363f9ed`) in streamable-HTTP mode at `/mcp`, protected by a generated bearer token, using a Grafana service account token minted at boot.
