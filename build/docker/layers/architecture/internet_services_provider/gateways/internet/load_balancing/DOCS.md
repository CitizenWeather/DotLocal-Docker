# Internet Load Balancing

## TODO

- [ ] Document upstream pool configuration for outbound load balancing across multiple ISP links
- [ ] Implement health-checked failover between WAN interfaces using keepalived or HAProxy
- [ ] Add latency and bandwidth metrics for each upstream link to Grafana dashboards
- [ ] Document how to configure weighted round-robin vs failover load balancing modes

## Outline

The internet load balancing layer distributes outbound traffic across multiple upstream links or service instances for redundancy and throughput optimization.

- Supports active-active and active-passive configurations for multi-WAN scenarios
- Keepalived (already in the fixed service list) handles virtual IP failover between host interfaces
- HAProxy or Nginx upstream pools can balance traffic across multiple gateway containers or WAN links
- Health checks poll each upstream link and remove failed paths from the rotation automatically
- Integrates with the NAT egress gateway to ensure correct source IP selection per upstream
- Status: keepalived config exists in `config/`; multi-WAN load balancing is a planned enhancement
