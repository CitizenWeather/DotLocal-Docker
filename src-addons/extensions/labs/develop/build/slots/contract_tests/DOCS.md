# Contract Testing Slot

## TODO

- [ ] Deploy Pact Broker as the contract testing registry implementation
- [ ] Document how to publish consumer-driven contracts from CI/CD pipelines
- [ ] Integrate Pact Broker with the CI/CD slot to gate deployments on contract verification
- [ ] Add Pact Broker at `pact.<ROOT_DOMAIN>` through the gateway

## Outline

The contract testing slot provides a self-hosted contract registry for consumer-driven contract testing, enabling safe API evolution across microservices.

- Pact Broker is the primary implementation, storing published consumer pacts and provider verification results
- Consumer services publish pact files to the broker from their CI/CD pipelines after test runs
- Provider services verify pacts against the broker and report results, blocking deployment on contract failures
- The broker integrates with the CI/CD slot via webhooks to trigger provider verification runs on new pact publications
- Accessible at `pact.<ROOT_DOMAIN>` with authentication via the IAM subsystem
- Status: optional developer lab slot — relevant for microservice-heavy development environments
