# Network Topology

## TODO

- [ ] Document containerlab topology YAML schema and how to extend it
- [ ] Add diagrams showing backbone vs default network segments
- [ ] Document FRR BGP/OSPF configuration options for the fabric router
- [ ] Add instructions for deploying `make network-lab` in a fresh environment

## Outline

Defines the physical and virtual network topology for the NetLocal stack, including containerlab-based simulated routing and dual-network segmentation.

- Backbone network (`localnet_backbone`, `169.254.0.0/16`) is internal-only, carrying DNS, CA, and registry traffic with static IPs
- Default network (`localnet_default`, `172.20.0.0/16`) carries application traffic routed through the gateway
- Containerlab topology in `core/` simulates a multi-hop network with FRR-based BGP/OSPF routing between virtual nodes
- `make network-lab` deploys the containerlab topology; requires containerlab to be installed on the host
- FRR config in `core/frr/` controls routing daemon configuration for the fabric router service
- Static IP assignments on the backbone follow the `169.254.0.x` scheme: DNS `.2`, Registry `.3`, CA `.4`
