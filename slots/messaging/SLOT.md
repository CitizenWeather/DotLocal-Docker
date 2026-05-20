# Slot: messaging

**Variable:** `MESSAGING_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=messaging`

## Contract

An implementation must:
- Expose a client port reachable from services on `localnet_default`
- Persist messages to a named volume when persistence is supported
- Set container name `netlocal_<broker>` for predictable DNS resolution within the stack

## Port conventions

| Implementation | Port | Protocol |
|---|---|---|
| `nats` / `nats-jetstream` | 4222 | NATS |
| `kafka` | 9092 | Kafka (Zookeeper on 2181 internally) |
| `rabbitmq` | 5672 | AMQP; management UI on 15672 |
| `redpanda` | 9092 | Kafka-compatible wire protocol |

## Available implementations

| Name | Image | Notes |
|---|---|---|
| `nats-jetstream` *(recommended)* | `nats:2.10-alpine` | JetStream persistence enabled |
| `nats` | `nats:2.10-alpine` | Core NATS, no persistence |
| `kafka` | `confluentinc/cp-kafka:latest` | Includes Zookeeper sidecar |
| `rabbitmq` | `rabbitmq:3-management-alpine` | AMQP; compose file planned |
| `redpanda` | `redpandadata/redpanda:latest` | Kafka-compatible, lighter; compose file planned |

## Adding a new implementation

1. Create `slots/messaging/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`
3. Add label `netlocal.component=messaging`
4. Set `MESSAGING_APP=<impl-name>` in `.env`
