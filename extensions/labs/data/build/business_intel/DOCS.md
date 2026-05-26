# Business Intelligence Stack

## TODO

- [ ] Deploy Apache Superset or Metabase as the BI visualization tool
- [ ] Connect the BI tool to the PostgreSQL database and configure dataset discovery
- [ ] Create starter dashboards for NetLocal infrastructure metrics (service usage, storage trends)
- [ ] Document the ETL pipeline from operational data sources to the BI schema

## Outline

The business intelligence stack provides data visualization, reporting, and analytics capabilities over data stored in the NetLocal environment.

- Apache Superset or Metabase serve as the primary BI front-end, accessible at `bi.<ROOT_DOMAIN>`
- Connects to PostgreSQL (via `DB_APP` slot) for operational data and to the data lake for historical analytics
- ETL pipelines transform raw operational data (DNS queries, certificate issuances, traffic logs) into BI-ready datasets
- Dashboards cover infrastructure KPIs, application usage trends, and capacity planning metrics
- User authentication is delegated to the IAM subsystem via OIDC integration
- Status: labs extension — requires the data lake and data catalog to be deployed first
