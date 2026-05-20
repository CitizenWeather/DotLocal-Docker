# Firewall Rules

## TODO

- [ ] Document default inbound and outbound firewall policy (default-deny vs default-allow)
- [ ] Create a rules inventory listing all current iptables/nftables rules and their purpose
- [ ] Add firewall rule testing to the health check pipeline
- [ ] Document how to add custom rules via a `config/firewall/rules.d/` drop-in directory

## Outline

The firewall service manages packet filtering rules that control traffic flow between the internet, the backbone network, and the default application network.

- Default policy isolates `localnet_backbone` from direct internet access; only the gateway and DNS resolver may forward packets
- iptables/nftables rules are applied at Docker network initialization and can be extended via config drop-ins
- Stateful connection tracking allows return traffic for established outbound connections without explicit inbound rules
- Rate limiting rules protect DNS (UDP/53) and ACME (TCP/443) endpoints from abuse
- Firewall rule changes are logged and forwarded to Loki; alerts fire on unexpected rule modifications
- Status: basic Docker network isolation is in place; explicit firewall rules are applied via bootstrap scripts
