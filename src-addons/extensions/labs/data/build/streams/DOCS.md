# Data Streams

## TODO

- [ ] Deploy Kafka Connect or Redpanda Connect for stream ingestion from infrastructure services
- [ ] Create connectors for PostgreSQL CDC (Debezium) and Prometheus remote write
- [ ] Document the stream processing topology and topic naming conventions
- [ ] Add stream lag monitoring to the Grafana observability dashboards

## Outline

The data streams layer enables real-time event streaming and stream processing for infrastructure and application data within the NetLocal labs environment.

- Built on Redpanda (Kafka-compatible) as the stream backbone; Kafka Connect handles source/sink connectors
- Debezium CDC connector captures PostgreSQL change events for real-time replication and audit trails
- Prometheus remote write pushes metrics into Redpanda topics for stream-based alerting
- Stream processors (Apache Flink or ksqlDB) apply transformations and aggregations in real time
- Topics feed both the data lake (for batch analytics) and the BI stack (for real-time dashboards)
- Status: labs extension — requires Redpanda as the `MESSAGING_APP` slot implementation
