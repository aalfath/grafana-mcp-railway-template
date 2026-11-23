# Grafana MCP server, official image pinned by version and digest.
FROM grafana/mcp-grafana:2.3.0@sha256:c27248b5919d09d64ea273ca1b128b32902c6796f6e2dfcd11849d4f1363f9ed

COPY --chmod=755 start.sh /app/start.sh

# Streamable HTTP on Railway's $PORT. The start script refuses to run without
# MCP_GRAFANA_SERVER_TOKEN, so the endpoint is never open.
ENV PORT=8000 \
    GOMAXPROCS=2
EXPOSE 8000
ENTRYPOINT ["/app/start.sh"]
