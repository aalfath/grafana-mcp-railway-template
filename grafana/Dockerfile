# Grafana OSS, official image pinned by version and digest.
FROM grafana/grafana:13.3.1@sha256:0615ec4fbd4072004b7d86b46ded63013a74b7d6eb1119273dd89e8fa25c13cf

USER root
COPY --chmod=755 start.sh /usr/local/bin/railway-start.sh

# Fixed settings for the template. Admin login, root URL and port come from
# Railway variables.
ENV GF_USERS_ALLOW_SIGN_UP=false \
    GF_AUTH_ANONYMOUS_ENABLED=false \
    GF_PATHS_DATA=/var/lib/grafana \
    GF_PATHS_PLUGINS=/var/lib/grafana/plugins \
    GOMAXPROCS=2 \
    PORT=3000

EXPOSE 3000
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
