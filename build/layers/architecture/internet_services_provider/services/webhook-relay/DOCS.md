# Webhook Relay Service

## TODO

- [ ] Deploy a webhook relay container (e.g., smee.io clone or webhook-relay open source)
- [ ] Document how to register webhooks from external services (GitHub, Stripe, etc.)
- [ ] Configure webhook signature verification for each registered provider
- [ ] Add webhook delivery logs to Loki for debugging failed deliveries

## Outline

The webhook relay service receives inbound webhook events from external internet services and forwards them to internal NetLocal services that are not directly internet-accessible.

- Solves the problem of receiving webhooks from public services (GitHub, payment processors, IoT platforms) when the local network has no public ingress
- Works by polling a cloud relay endpoint or using a tunnel (e.g., ngrok-compatible) and forwarding payloads to internal services
- Each registered webhook target has a configured URL path, signature secret, and forwarding destination
- Failed deliveries are retried with exponential backoff and stored in a dead-letter queue
- Integrates with the CI/CD slot to trigger pipeline runs on Git push events from an external Gitea mirror
- Status: placeholder — no webhook relay service is deployed by default
