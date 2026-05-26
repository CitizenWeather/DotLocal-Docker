# NAT Egress Gateway

## TODO

- [ ] Document iptables/nftables NAT masquerade rules applied by the egress gateway
- [ ] Add SNAT source IP configuration for multi-WAN scenarios
- [ ] Document how to add static DNAT rules for inbound port forwarding
- [ ] Test egress behavior when the primary WAN link fails and traffic reroutes

## Outline

The NAT egress gateway manages network address translation for outbound traffic leaving the `localnet_default` and `localnet_backbone` networks to the internet.

- Applies MASQUERADE/SNAT rules so containers can reach the internet using the host's external IP
- Configured via Docker network settings and supplementary iptables rules applied at bootstrap
- Source IP selection for multi-WAN deployments is coordinated with the load balancing layer
- DNAT rules can expose specific internal services to inbound internet traffic on defined ports
- Egress policies can restrict which subnets or containers are permitted to initiate outbound connections
- Status: basic NAT is handled by Docker's built-in networking; advanced egress policies are planned
