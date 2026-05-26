# Object Storage Service

## TODO

- [ ] Document MinIO deployment configuration and initial bucket setup
- [ ] Configure MinIO TLS using Step-CA certificates via the gateway
- [ ] Create example bucket policies for common use cases (backups, media, artifacts)
- [ ] Add MinIO storage capacity and request rate metrics to Grafana dashboards

## Outline

The object storage service provides S3-compatible object storage for the NetLocal environment using MinIO as the primary implementation.

- MinIO is the `STORAGE_APP` slot implementation, selected via `STORAGE_APP=minio` in `.env`
- Exposes the S3 API at `s3.<ROOT_DOMAIN>` and the MinIO Console at `minio.<ROOT_DOMAIN>` through the gateway
- Pre-configured buckets for common uses: `backups`, `artifacts`, `media`, `logs`
- Access keys and secret keys are configured via `.env` or Vault secrets; bucket policies enforce access control
- Integrates with LocalStack S3 emulation for AWS SDK-compatible access patterns
- Used by backups, the data lake extension, CI/CD artifact storage, and the web hosting provider layer
