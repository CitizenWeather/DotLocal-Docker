# DotLocal-Docker

A minimal Traefik reverse proxy that routes `*.localhost` domains to Docker services — no DNS configuration required.

## How it works

`*.localhost` is natively resolved to `127.0.0.1` by modern browsers and most operating systems. Traefik watches the Docker socket and routes incoming requests based on container labels, so each service is reachable at `<name>.localhost` as soon as it starts.

## Quick start

```bash
make up
```

- Traefik dashboard: http://traefik.localhost
- Example whoami service: http://whoami.localhost

## Adding your own services

Attach your service to the `dotlocal` network and add two labels:

```yaml
services:
  myapp:
    image: myapp:latest
    networks:
      - dotlocal
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.localhost`)"

networks:
  dotlocal:
    external: true
```

If the service exposes multiple ports, specify which one Traefik should use:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`myapp.localhost`)"
  - "traefik.http.services.myapp.loadbalancer.server.port=3000"
```

## Commands

| Command        | Description                  |
|----------------|------------------------------|
| `make up`      | Start Traefik in the background |
| `make down`    | Stop all services            |
| `make restart` | Restart all services         |
| `make ps`      | Show running containers      |
| `make logs`    | Tail logs                    |

## Requirements

- Docker with Compose plugin (v2)
