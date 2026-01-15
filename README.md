[![Automated Release & Publish](https://github.com/gebhug/tailscale-proxy/actions/workflows/release.yml/badge.svg)](https://github.com/gebhug/tailscale-proxy/actions/workflows/release.yml)

# tailscale-proxy

A Docker container that extends the official Tailscale image with built-in proxy configuration for Tailscale's Serve and Funnel features. This allows you to easily expose your Docker services to your Tailscale network (Serve) or to the public internet (Funnel) using simple environment variables.

## What This Does

This container automatically configures Tailscale to act as a reverse proxy for your Docker services. Instead of manually creating and managing Tailscale serve configuration files, you can use environment variables to:

- **Proxy HTTP/HTTPS traffic** from your Tailscale domain to any backend service
- **Enable Tailscale Serve** to make services accessible within your Tailscale network (tailnet)
- **Enable Tailscale Funnel** to expose services to the public internet (optional)

The container dynamically generates a Tailscale serve configuration (`serve.json`) at startup based on your environment variables, making it simple to deploy and configure.

## How It Works

The entrypoint script (`entrypoint.sh`) reads environment variables and generates a `serve.json` configuration file that tells Tailscale how to proxy requests. This configuration:

1. Sets up HTTPS on port 443
2. Proxies all requests (`/`) to your specified backend service
3. Optionally enables Funnel to allow public internet access

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TS_AUTHKEY` | Yes | - | Your Tailscale authentication key. Get this from the [Tailscale admin console](https://login.tailscale.com/admin/settings/keys) |
| `TS_SERVE_PROXY` | Yes | - | The backend service URL to proxy to (e.g., `http://service-name:port`) |
| `TS_SERVE_ALLOWFUNNEL` | No | `false` | Set to `true` to enable Funnel and expose your service to the public internet |
| `TS_STATE_DIR` | No | - | Directory to store Tailscale state (recommended: `/var/lib/tailscale`) |

## Usage

### Using Docker Compose (Recommended)

The included `compose.yml` provides a complete example of how to use this container. Here's how to get started:

1. **Copy the compose.yml file** to your project directory

2. **Edit the configuration** with your values:
   ```yaml
   services:
     tailscale-proxy:
       image: ghcr.io/gebhug/tailscale-proxy:latest
       container_name: tailscale-proxy-1
       hostname: name-you-want-before-your-tailscale-domain  # This becomes: hostname.your-tailnet.ts.net
       environment:
         - TS_AUTHKEY=your_tskey                             # Your Tailscale auth key
         - TS_SERVE_PROXY=http://proxied-service-1:80        # Backend service to proxy
         - TS_SERVE_ALLOWFUNNEL=false                         # Enable public access via Funnel
         - TS_STATE_DIR=/var/lib/tailscale
       volumes:
         - tailscale-state:/var/lib/tailscale
     # Your actual service that you want to proxy
     getting-started:
       container_name: proxied-service-1
       image: docker/getting-started
   volumes:
      tailscale-state:
   ```

3. **Start the services**:
   ```bash
   docker compose up -d
   ```

4. **Access your service**:
   - **Via Tailscale (Serve)**: `https://hostname.your-tailnet.ts.net`
   - **Via Public Internet (Funnel)**: `https://hostname.your-tailnet.ts.net` (if `TS_SERVE_ALLOWFUNNEL=true`)

### Using Docker Run

```bash
docker run -d \
  --name tailscale-proxy \
  --hostname my-service \
  -e TS_AUTHKEY=tskey-auth-xxxxx \
  -e TS_SERVE_PROXY=http://backend-service:8080 \
  -e TS_SERVE_ALLOWFUNNEL=false \
  -e TS_STATE_DIR=/var/lib/tailscale \
  ghcr.io/gebhug/tailscale-proxy:latest
```

## Example: Exposing a Web Application

Let's say you have a web application running in a container named `my-webapp` on port 3000:

```yaml
services:
  tailscale-proxy:
    image: ghcr.io/gebhug/tailscale-proxy:latest
    hostname: webapp
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}  # Store your key in an .env file
      - TS_SERVE_PROXY=http://my-webapp:3000
      - TS_SERVE_ALLOWFUNNEL=false  # Only accessible within your tailnet
      - TS_STATE_DIR=/var/lib/tailscale

  my-webapp:
    image: your-webapp-image
    container_name: my-webapp
    # No need to expose ports publicly!
```

After starting with `docker compose up -d`, your webapp will be accessible at `https://webapp.your-tailnet.ts.net` to anyone on your Tailscale network.

## Security Notes

- **Auth Keys**: Keep your `TS_AUTHKEY` secure! Consider using Docker secrets or environment files that are not committed to version control.
- **Funnel**: Only enable `TS_SERVE_ALLOWFUNNEL=true` if you want your service to be publicly accessible on the internet. Use with caution.
- **HTTPS**: Tailscale automatically provides HTTPS certificates, so your traffic is always encrypted.

## Generated Configuration

For reference, the container generates a `serve.json` file that looks like this:

```json
{
  "TCP": {
    "443": {
      "HTTPS": true
    }
  },
  "Web": {
    "${TS_CERT_DOMAIN}:443": {
      "Handlers": {
        "/": {
          "Proxy": "http://your-backend:port"
        }
      }
    }
  },
  "AllowFunnel": {
    "${TS_CERT_DOMAIN}:443": false
  }
}
```

This configuration is automatically created based on your environment variables, so you don't need to manage it manually.

## Troubleshooting

- **Container won't start**: Verify your `TS_AUTHKEY` is valid and not expired
- **Can't access the service**: Check that the `TS_SERVE_PROXY` URL is correct and the backend service is running
- **Public access not working**: Ensure Funnel is enabled in your Tailscale admin console and `TS_SERVE_ALLOWFUNNEL=true`

## License

See [LICENSE](LICENSE) file for details.

