# Extending the Stack

NetLocal is designed to grow. You can add new swappable implementations for existing slots, or add entirely new extension packs.

---

## Adding a new swappable implementation

To add an alternative implementation for an existing slot (e.g. a new DNS resolver or a new database):

### 1. Create the compose file

```
slots/<slot>/<impl-name>/docker-compose.yml
```

For example, to add `unbound` as a DNS resolver:

```
slots/dns/unbound/docker-compose.yml
```

### 2. Follow the network attachment pattern

Infrastructure services (DNS, CA, registry) go on the backbone with a static IP:

```yaml
services:
  dns:
    image: mvance/unbound:latest
    container_name: netlocal_dns
    networks:
      localnet_backbone:
        ipv4_address: 169.254.0.2    # use the IP already assigned to this slot

networks:
  localnet_backbone:
    external: true
```

Application services (database, cache, storage, etc.) go on the default network:

```yaml
services:
  mydb:
    image: mydb:latest
    container_name: netlocal_mydb
    networks:
      - localnet_default

networks:
  localnet_default:
    external: true
```

### 3. Add the role label

Every service must carry a `netlocal.component` label matching the slot name:

```yaml
labels:
  - netlocal.component=dns    # or: ca, gateway, database, cache, etc.
```

### 4. Verify the Makefile picks it up

The Makefile uses a wildcard-based `include_if` helper. As long as your file is at `slots/<slot>/<impl>/docker-compose.yml` and the corresponding `*_APP` variable is set in `.env`, it will be included automatically. No Makefile edits required for existing slots.

If you are adding a **new slot** (not just a new implementation of an existing one):

- Add a line to the `COMPOSE_FILES` block in the Makefile:
  ```makefile
  COMPOSE_FILES += $(call include_app,myslot,$(MYSLOT_APP))
  ```
- Add `MYSLOT_APP=<default-impl>` to `.env.example`.

### 5. Document it

Add a row to the relevant table in [docs/slots.md](slots.md).

---

## Adding a new extension

Extensions are standalone service packs activated by a profile tag. They do not require Makefile changes.

### 1. Create the compose file

```
extensions/tags/<tag>/docker-compose.yml
```

```yaml
services:
  mytool:
    image: mytool:latest
    container_name: netlocal_mytool
    networks:
      - localnet_default

networks:
  localnet_default:
    external: true
```

### 2. Activate the extension

Add the tag to `EXTENSION_TAGS` in `.env`:

```
EXTENSION_TAGS=mytag
```

Then restart:

```bash
make restart
```

The Makefile iterates `EXTENSION_TAGS` and adds `-f extensions/tags/<tag>/docker-compose.yml` for each tag automatically.

### 3. Document it

Add a section to [docs/extensions.md](extensions.md) describing the services, ports, dependencies, and any configuration needed.

---

## Conventions to follow

- **Container name:** `netlocal_<service>` for all managed services
- **Role label:** `netlocal.component=<slot>` on every service
- **Networks:** declare as `external: true`; never create new networks in implementation files
- **Volumes:** use named volumes (not bind mounts to `volumes/`) for persistent data
- **Config files:** mount read-only (`:ro`) where possible
- **Secrets:** reference variables from `.env` using `${VAR_NAME}` interpolation; never hardcode credentials
- **Profiles:** extension services must declare `profiles: ["tag-<tag>"]`; barebones implementations must not use profiles
