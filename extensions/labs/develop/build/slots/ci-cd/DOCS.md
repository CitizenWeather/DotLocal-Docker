# CI/CD Slot

## TODO

- [ ] Write compose files for Drone CI and Woodpecker CI as slot implementations
- [ ] Document webhook integration with the Gitea git slot for push-triggered pipelines
- [ ] Configure pipeline artifact storage in the object storage slot (MinIO)
- [ ] Add CI/CD runner health checks to `scripts/healthcheck.py`

## Outline

The CI/CD slot provides a self-hosted continuous integration and delivery pipeline service that integrates with the local git server.

- Swappable slot: supported implementations include Drone CI, Woodpecker CI, and Forgejo Actions
- Triggered by webhook events from the Gitea/Forgejo git slot on push, PR, and tag events
- Pipeline artifacts (test reports, built binaries, Docker images) are stored in the object storage slot (MinIO)
- Built Docker images are pushed to the container registry slot
- Pipeline configuration lives in `.drone.yml` or `.woodpecker.yml` files in each repository
- Accessible at `ci.<ROOT_DOMAIN>` through the gateway with OAuth2 authentication via the IAM subsystem
