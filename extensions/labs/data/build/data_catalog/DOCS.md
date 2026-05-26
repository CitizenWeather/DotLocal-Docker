# Data Catalog

## TODO

- [ ] Deploy Apache Atlas or DataHub as the data catalog implementation
- [ ] Auto-discover and register PostgreSQL tables and MinIO buckets as catalog assets
- [ ] Document metadata tagging conventions for datasets in the NetLocal environment
- [ ] Integrate the catalog with the BI stack for dataset discovery in Superset/Metabase

## Outline

The data catalog provides a searchable inventory of all data assets in the NetLocal environment, enabling data discovery and governance.

- Apache Atlas or DataHub are the candidate catalog implementations, accessible at `catalog.<ROOT_DOMAIN>`
- Automatically discovers and registers database tables, object storage buckets, and Kafka/Redpanda topics as catalog assets
- Metadata includes schema definitions, data lineage, ownership, classification (PII, public, internal), and sample data
- Lineage tracking shows how data flows from source systems through ETL pipelines to BI dashboards
- Integrates with the IAM subsystem to enforce data access policies at the catalog level
- Status: labs extension — depends on the data lake and operational data sources being available
