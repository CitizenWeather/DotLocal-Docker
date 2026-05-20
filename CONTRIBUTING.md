# Contributing to DotLocal-Docker

## Adding a New Swappable Implementation

Each component role (DNS, CA, gateway, etc.) supports multiple implementations selected via `.env`. Adding a new one takes five steps:

1. **Create the directory**

   ```
   apps/localnet/barebones/<role>/<implementation>/docker-compose.yml
   ```

   Example: `apps/localnet/barebones/dns/unbound/docker-compose.yml`

2. **Write the compose file** following these conventions:

   ```yaml
   version: '3.8'

   services:
     <service-name>:
       image: <image>:<pinned-version>
       container_name: netlocal_<service-name>
       networks:
         localnet_backbone:            # for infrastructure roles (dns, ca, registry)
           ipv4_address: 169.254.x.x  # reserve a static IP in the backbone subnet
         # OR:
         - localnet_default            # for application-layer roles (gateway, db, etc.)
       restart: unless-stopped
       security_opt:
         - no-new-privileges:true
       labels:
         - "netlocal.component=<role>"
       healthcheck:
         test: ["CMD", ...]
         interval: 30s
         timeout: 10s
         retries: 3
         start_period: 10s
       logging:
         driver: json-file
         options:
           max-size: "10m"
           max-file: "3"
   ```

3. **Update `.env.example`** — add your implementation name to the options comment for the relevant variable.

4. **Test it**

   ```bash
   cp .env.example .env
   # Set the relevant *_APP variable to your implementation
   make validate-env
   make validate-compose
   make up
   make health
   ```

5. **Open a PR** — fill in the PR template checklist.

---

## Adding a New Extension

Extensions are optional feature packs enabled via `EXTENSION_TAGS` in `.env`.

1. Create `apps/extensions/<tag>/docker-compose.yml`
2. All services in the compose should use the Docker Compose profile `tag-<tag>` (so they're only started when explicitly enabled)
3. Document the extension in a `README.md` next to the compose file
4. Add the tag name to the `EXTENSION_TAGS` options comment in `.env.example`

---

## Adding a Fixed Always-On Service

Services that always run (not swappable) go in:
- `apps/localnet/barebones/<category>/docker-compose.yml` — mandatory infrastructure
- `apps/localnet/enhancements/<name>/docker-compose.yml` — optional enhancements

After adding, wire it into the Makefile via the `barebones_svc` or `enhancement_svc` helper.

---

## Code Style

- **YAML**: 2-space indent; max line length 120; no trailing whitespace
- **Shell**: POSIX-compatible where possible; `set -e` at the top; quote all variables
- **Docker images**: always pin to a specific version tag (never `latest` for infrastructure)
- **Secrets**: never hardcode credentials; always read from environment variables

---

## PR Checklist

Before opening a PR, confirm:

- [ ] `make validate-compose` passes with the new service included
- [ ] `shellcheck` passes on any new shell scripts (`make lint`)
- [ ] `yamllint` passes on new YAML files (`make lint`)
- [ ] New service has `restart: unless-stopped`, `healthcheck`, and `logging` blocks
- [ ] `.env.example` updated if a new env var was introduced
- [ ] `CHANGELOG.md` updated with a brief entry
