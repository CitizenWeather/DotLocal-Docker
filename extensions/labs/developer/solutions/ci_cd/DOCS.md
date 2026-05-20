# CI/CD Full Solution

## TODO

- [ ] Document the complete CI/CD stack: Gitea + Woodpecker + Harbor + MinIO + package mirrors
- [ ] Create a quickstart guide for onboarding a new repository into the CI/CD pipeline
- [ ] Add end-to-end pipeline test that builds, tests, pushes, and deploys a sample app
- [ ] Document rollback procedures for failed deployments

## Outline

The CI/CD full solution integrates all developer lab slots into a complete build, test, and deploy pipeline for the NetLocal environment.

- Combines: git slot (Gitea/Forgejo) + CI/CD slot (Woodpecker) + registry slot (Harbor) + object storage slot (MinIO) + pkg-mirrors
- A developer pushes code to Gitea, a webhook triggers Woodpecker, which runs tests, builds a Docker image, pushes to Harbor, and deploys to the stack
- Package mirror slots are pre-configured in Woodpecker pipeline definitions to avoid public registry rate limits
- Deployment step updates Docker Compose services on the target host via SSH or the Supervisor API
- Contract tests (Pact Broker slot) gate deployments on successful provider verification
- Status: functional when all constituent slots are deployed; full automation requires the Supervisor API deploy endpoint
