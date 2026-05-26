# Data Lake

## TODO

- [ ] Deploy Apache Hive Metastore + MinIO as the data lake foundation
- [ ] Configure Trino or Spark to query Parquet/ORC files stored in MinIO
- [ ] Create ingestion pipelines from Loki logs, Prometheus metrics, and PostgreSQL snapshots
- [ ] Document the data lake directory layout convention (`raw/`, `curated/`, `aggregated/`)

## Outline

The data lake provides a centralized store for large-scale structured and semi-structured data, enabling SQL-based analytics over historical infrastructure and application data.

- Built on MinIO (S3-compatible) as the storage layer with Apache Hive Metastore for schema management
- Trino or Apache Spark serve as the query engines, enabling SQL queries over Parquet files in MinIO
- Ingestion pipelines pull data from Loki (logs), Prometheus (metrics snapshots), and PostgreSQL (operational records)
- Data is organized in a three-zone layout: `raw/` (as-ingested), `curated/` (cleaned), `aggregated/` (BI-ready)
- Integrates with the data catalog for asset registration and the BI stack for dashboard queries
- Status: labs extension — large memory footprint; only deploy on hosts with 8GB+ RAM available
