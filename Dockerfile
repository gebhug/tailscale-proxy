FROM ghcr.io/tailscale/tailscale:v1.96.5

WORKDIR /config

ENV TS_SERVE_CONFIG=/config/serve.json

COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
