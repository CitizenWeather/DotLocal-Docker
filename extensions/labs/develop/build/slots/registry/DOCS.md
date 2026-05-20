# Container Registry Slot

## TODO

- [ ] Deploy a container registry (Docker Distribution or Harbor) as the slot implementation
- [ ] Configure the registry to use MinIO as the blob storage backend
- [ ] Add the local registry CA cert to Docker daemon `insecure-registries` or trusted CAs
- [ ] Document how to push and pull images using `registry.<ROOT_DOMAIN>` as the registry host

## Outline

The container registry slot provides a self-hosted Docker/OCI image registry for storing images built by CI/CD pipelines and used by the local Docker Compose stack.

- Swappable slot: Docker Distribution (plain registry) and Harbor (enterprise features, scanning) are supported implementations
- Registry blobs are stored in the object storage slot (MinIO) for scalable, durable image storage
- Integrated with the CI/CD slot: build pipelines push images here after successful builds
- TLS certificates from Step-CA enable secure HTTPS access at `registry.<ROOT_DOMAIN>`
- Image vulnerability scanning (Harbor) checks pushed images against CVE databases automatically
- Docker Compose services reference `registry.<ROOT_DOMAIN>/<image>:<tag>` to pull locally-built images
