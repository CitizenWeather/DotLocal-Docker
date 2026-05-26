# Slot: ntp

**Variable:** `NTP_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=ntp`

## Contract

An implementation must:

- Serve NTP on UDP port 123
- Accept upstream server configuration via `NTP_SERVERS` environment variable
- Be reachable from services on `localnet_default`

## Required environment variables

| Variable      | Purpose                              | Default                            |
|---------------|--------------------------------------|------------------------------------|
| `NTP_SERVERS` | Comma-separated upstream NTP servers | `time.cloudflare.com,pool.ntp.org` |

## Available implementations

| Name                     | Image               | Notes                               |
|--------------------------|---------------------|-------------------------------------|
| `chrony` *(recommended)* | `cturra/ntp:latest` | Lightweight chrony-based NTP server |

## Adding a new implementation

1. Create `slots/ntp/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`
3. Serve NTP on UDP 123
4. Add label `netlocal.component=ntp`
5. Set `NTP_APP=<impl-name>` in `.env`
