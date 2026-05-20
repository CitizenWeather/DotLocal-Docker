# Extensions

Extensions are optional service packs that activate via Docker Compose profiles. They live in `apps/extensions/<tag>/` and are enabled by listing their tags in `EXTENSION_TAGS` in `.env`.

---

## How extensions work

Each extension pack is a `docker-compose.yml` file with `profiles: ["tag-<tag>"]` on every service. The Makefile includes the file and activates the profile for every tag in `EXTENSION_TAGS`:

```makefile
# For each tag in EXTENSION_TAGS:
# --profile tag-<tag> -f apps/extensions/<tag>/docker-compose.yml
```

Services in an inactive extension profile are defined but not started.

---

## Enabling extensions

Set `EXTENSION_TAGS` in `.env` to a space-separated list of tags, then restart:

```bash
# In .env:
EXTENSION_TAGS=iot chaos

# Then:
make restart
```

To disable an extension, remove its tag from `EXTENSION_TAGS` and restart.

---

## Available extensions

### `iot` — IoT / MQTT / LoRaWAN

Adds an MQTT broker and a LoRaWAN network server.

| Service | Image | Role | URL / Port |
|---|---|---|---|
| Mosquitto | `eclipse-mosquitto:2.0` | MQTT broker | `mqtt.net.local:1883` |
| ChirpStack | `chirpstack/chirpstack:4` | LoRaWAN network server | `lora.net.local` |

**Dependencies:** ChirpStack requires PostgreSQL. Ensure `DB_APP=postgres` is set.

**ChirpStack database:** Uses a separate `chirpstack` database in PostgreSQL. The `CHIRPSTACK_DB_PASSWORD` secret must be set.

**Mosquitto config:** Anonymous connections are disabled by default. Edit `apps/extensions/iot/config/mosquitto.conf` to configure authentication.

---

### `chaos` — Chaos engineering

Adds tools for deliberately injecting network faults to test service resilience.

| Service | Image | Role | Port |
|---|---|---|---|
| ToxiProxy | `ghcr.io/shopify/toxiproxy:2.7.0` | Programmable network proxy with fault injection | 8474 (API), 8080 (proxy) |
| Pumba | `gaiaadm/pumba:latest` | Docker container chaos (delays, packet loss, kills) | — |

**ToxiProxy usage:** Create proxies via the HTTP API at port 8474, then route test traffic through them. Inject toxics (latency, bandwidth limits, connection resets) to simulate degraded conditions.

**Pumba usage:** Pumba runs on a schedule (`--interval 5m`) applying network emulation (`netem delay --time 1000 --jitter 500`) to containers. Edit the `command:` in `apps/extensions/chaos/docker-compose.yml` to target specific containers.

**Warning:** Pumba requires `cap_add: NET_ADMIN`. Do not run the chaos extension in production environments.

---

### `legacy` — Legacy protocols

Adds servers for older internet protocols, useful for historical emulation or research.

| Service | Image | Role | Port |
|---|---|---|---|
| Gemini | `gemini/gemini-server:latest` | Gemini protocol server | 1965 |
| Gopher | `docker-gopher` | Gopher protocol server | 70 |

Content roots for both services are mounted from `apps/extensions/legacy/<service>/`. Add `.gmi` files for Gemini and a `gophermap` for Gopher.

---

### `labs` *(planned)*

Experimental services. Not yet implemented.
