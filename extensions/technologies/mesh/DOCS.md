# Mesh Networking

## TODO

- [ ] Deploy a mesh networking daemon (BATMAN-adv, Babel, or Yggdrasil) in a container
- [ ] Document how to peer mesh nodes across multiple NetLocal instances via site-to-site VPN
- [ ] Configure automatic route advertisement for mesh-connected subnets
- [ ] Add mesh topology visualization and link quality metrics to Grafana

## Outline

The mesh networking extension enables dynamic, self-healing network topologies within and between NetLocal deployments using mesh routing protocols.

- Supports mesh protocols: BATMAN-adv (Layer 2), Babel (Layer 3), or Yggdrasil (overlay IPv6 mesh)
- Mesh nodes automatically discover peers and establish direct routes, eliminating single points of failure
- Integrates with the site-to-site VPN addon for cross-site mesh connectivity over encrypted tunnels
- Mesh routing information is exported to FRR for integration with the backbone BGP/OSPF topology
- Suitable for multi-access point Wi-Fi deployments and distributed NetLocal lab environments
- Status: experimental — mesh protocol selection depends on the target hardware and network layer requirements
