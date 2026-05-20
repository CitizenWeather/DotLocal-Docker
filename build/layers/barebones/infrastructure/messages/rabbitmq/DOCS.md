# RabbitMQ Message Broker

## TODO

- [ ] Write the RabbitMQ compose file at the `messaging` slot path for `MESSAGING_APP=rabbitmq`
- [ ] Document exchange, queue, and binding configuration for NetLocal infrastructure events
- [ ] Add RabbitMQ management UI access at `rabbitmq.<ROOT_DOMAIN>` through the gateway
- [ ] Export RabbitMQ metrics via the Prometheus plugin for Grafana dashboards

## Outline

RabbitMQ is a swappable AMQP message broker implementation for the `MESSAGING_APP` slot in the NetLocal stack.

- Selected by setting `MESSAGING_APP=rabbitmq` in `.env`; compose file lives at `apps/localnet/barebones/messaging/rabbitmq/`
- Provides AMQP 0-9-1 protocol support for pub/sub and work queue patterns used by the event bus
- The management plugin exposes a web UI and REST API for queue inspection and message tracing
- Persistence is configured with durable queues and message acknowledgements for reliability
- RabbitMQ attaches to `localnet_default` and is accessible to application services at `rabbitmq.<ROOT_DOMAIN>:5672`
- Competes with Redpanda as the messaging slot implementation; choose based on AMQP vs Kafka protocol needs
