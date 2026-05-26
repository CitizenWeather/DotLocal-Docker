# Event Bus

## TODO

- [ ] Choose and document the default event bus implementation (RabbitMQ or Redpanda)
- [ ] Define standard event schemas for DNS registration, cert issuance, and service lifecycle events
- [ ] Document how services publish and subscribe to events via the bus
- [ ] Add event bus health check to `scripts/healthcheck.py`

## Outline

The event bus provides an asynchronous messaging backbone for the dotlocal authority, enabling loosely-coupled communication between core infrastructure services.

- Swappable via the `MESSAGING_APP` variable in `.env`; supported implementations include RabbitMQ and Redpanda (Kafka-compatible)
- Core infrastructure events (DNS record changes, certificate issuance, service registration) are published to the bus
- Downstream consumers (IAM, operations, observability) react to events without tight coupling to producers
- Sits on the `localnet_backbone` network to isolate infrastructure messaging from application traffic
- Exchange/topic naming follows a `netlocal.<subsystem>.<event>` convention
- Status: swappable slot exists; event schema definitions are in progress
