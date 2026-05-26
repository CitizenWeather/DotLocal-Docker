# Object Storage Slot (Developer)

## TODO

- [ ] Document MinIO bucket layout for developer artifacts (build cache, test fixtures, binaries)
- [ ] Configure lifecycle policies to auto-expire old CI build artifacts
- [ ] Add MinIO storage metrics to the developer lab Grafana dashboard
- [ ] Document S3 SDK configuration for accessing the local MinIO from developer tools

## Outline

The developer object storage slot provides S3-compatible artifact and build cache storage scoped to the developer lab environment.

- Uses MinIO as the implementation, consistent with the base `STORAGE_APP` slot
- Pre-configured buckets: `build-cache`, `test-artifacts`, `docker-layer-cache`, `release-binaries`
- CI/CD pipelines write build outputs here and read cached layers to speed up repeat builds
- Lifecycle rules automatically delete artifacts older than a configurable retention period (default: 30 days)
- Accessible via S3 API at `s3://obj-storage-dev/` using the MinIO endpoint at `s3.<ROOT_DOMAIN>`
- Status: shares the base object storage slot; developer-specific bucket layout requires initialization scripts
