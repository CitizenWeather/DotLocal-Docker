# Slot: storage

**Variable:** `STORAGE_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=storage`

## Contract

An implementation must:

- Expose an S3-compatible API on port 9000
- Accept credentials from environment variables
- Optionally expose a web console

## Required environment variables

| Variable              | Purpose                |
|-----------------------|------------------------|
| `MINIO_ROOT_USER`     | Storage admin username |
| `MINIO_ROOT_PASSWORD` | Storage admin password |

## Available implementations

| Name                    | Image                        | Ports                      |
|-------------------------|------------------------------|----------------------------|
| `minio` *(recommended)* | `minio/minio:latest`         | 9000 (API), 9001 (console) |
| `seaweedfs`             | `chrislusf/seaweedfs:latest` | 9000 (S3 API)              |

## Adding a new implementation

1. Create `slots/storage/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`
3. Expose port 9000 (S3-compatible)
4. Add label `netlocal.component=storage`
5. Set `STORAGE_APP=<impl-name>` in `.env`
