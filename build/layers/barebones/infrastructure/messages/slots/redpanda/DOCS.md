# Redpanda Message Broker

## TODO

- [ ] Write the Redpanda compose file at the messaging slot path for `MESSAGING_APP=redpanda`
- [ ] Document Kafka-compatible topic configuration for NetLocal infrastructure events
- [ ] Add Redpanda Console (web UI) at `redpanda.<ROOT_DOMAIN>` through the gateway
- [ ] Export Redpanda metrics to Prometheus for Grafana dashboards

## Outline

Redpanda is a Kafka-compatible message broker implementation for the `MESSAGING_APP` slot, offering high throughput with a simpler operational model than Apache Kafka.

- Selected by setting `MESSAGING_APP=redpanda` in `.env`; compose file lives at `apps/localnet/barebones/messaging/redpanda/`
- Fully Kafka API-compatible: existing Kafka clients (librdkafka, kafka-python, etc.) work without code changes
- Single-binary, no ZooKeeper required — simpler to deploy and operate than standard Kafka in a local environment
- Redpanda Console provides a web UI for topic management, consumer group monitoring, and message inspection
- Integrates with the data streams extension for event-driven data pipelines within the labs environment
- Competes with RabbitMQ as the messaging slot; prefer Redpanda when Kafka-protocol compatibility is required
