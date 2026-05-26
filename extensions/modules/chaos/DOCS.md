# Chaos Engineering Module

## TODO

- [ ] Deploy Chaos Monkey or Pumba for container-level fault injection
- [ ] Document available chaos experiments: network partition, container kill, CPU/memory stress
- [ ] Implement a chaos schedule that runs experiments during defined maintenance windows
- [ ] Add chaos experiment results to the observability stack for post-mortem analysis

## Outline

The chaos engineering module provides fault injection and resilience testing tools to validate that the NetLocal stack degrades gracefully under adverse conditions.

- Activated via the `chaos` extension tag in `EXTENSION_TAGS`; compose file is at `apps/extensions/chaos/docker-compose.yml`
- Supported experiments: container kill (Pumba), network partition (tc/iptables), latency injection, CPU/memory stress (stress-ng)
- Experiments are defined as YAML schedules specifying targets (by `netlocal.component` label), experiment type, duration, and magnitude
- Integration with the observability stack captures service behavior during and after experiments for SLO validation
- Works in conjunction with the artificials module to run realistic traffic patterns during fault injection
- Status: extension exists in `apps/extensions/chaos/`; experiment scheduling UI is planned
