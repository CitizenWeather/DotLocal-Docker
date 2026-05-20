# Mimicking Engine

## TODO

- [ ] Define the traffic mirroring architecture (tap point, mirror target, replay buffer)
- [ ] Implement service response recording and playback for offline testing
- [ ] Document how to configure a mirror target to capture production traffic for lab replay
- [ ] Add mimicking accuracy metrics (response latency delta, payload match rate) to Grafana

## Outline

The mimicking engine captures real service traffic and replays it against test or staging services, enabling realistic load testing without impacting production systems.

- Traffic mirroring taps into the `localnet_default` network to capture HTTP request/response pairs from selected services
- Captured traffic is stored in the object storage slot (MinIO) as structured replay files
- Replay mode re-sends recorded requests against a target service and compares responses for regression testing
- Response simulation mode can serve pre-recorded responses without a real backend, enabling offline development
- Integrates with the artificials module — recorded traffic can be used to configure realistic artificial load generators
- Status: experimental — traffic capture infrastructure is planned; replay tooling is in design
