#!/bin/sh
set -Eeuo pipefail

FUNNEL="${TS_SERVE_ALLOWFUNNEL:-false}"

CONF_DIR=/config
mkdir -p "$CONF_DIR"

cat > "$CONF_DIR/serve.json" <<EOF
{
  "TCP": {
    "443": {
      "HTTPS": true
    }
  },
  "Web": {
    "\${TS_CERT_DOMAIN}:443": {
      "Handlers": {
        "/": {
          "Proxy": "${TS_SERVE_PROXY}"
        }
      }
    }
  },
  "AllowFunnel": {
    "\${TS_CERT_DOMAIN}:443": ${TS_SERVE_ALLOWFUNNEL}
  }
}
EOF

echo "Wrote $CONF_DIR/serve.json with AllowFunnel=${FUNNEL}"

if command -v /usr/local/bin/containerboot >/dev/null 2>&1; then
  exec /usr/local/bin/containerboot
else
  exec tailscaled
fi