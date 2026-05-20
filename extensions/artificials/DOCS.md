# Artificial & Simulated Services

## TODO

- [ ] Document available artificial service types (traffic generators, mock APIs, synthetic clients)
- [ ] Create a configurable HTTP traffic generator for load testing the gateway
- [ ] Add DNS query flood simulation for testing CoreDNS performance under load
- [ ] Integrate artificial service metrics with Prometheus for baseline performance profiling

## Outline

The artificials extension provides simulated services and traffic generators that mimic real-world workloads for testing, benchmarking, and chaos engineering within the NetLocal stack.

- Traffic generators produce synthetic HTTP, DNS, and AMQP workloads to stress-test infrastructure services
- Mock API endpoints simulate external services (payment gateways, cloud APIs) for offline development
- Synthetic clients continuously probe services and report availability and latency metrics to Prometheus
- Activated as an extension tag in `EXTENSION_TAGS`; compose files use Docker Compose profiles for selective deployment
- Works in conjunction with the chaos engineering module to combine fault injection with realistic traffic patterns
- Status: experimental — specific artificial service containers are being developed
