# Underground & Dark Net Services

## TODO

- [ ] Deploy Tor hidden service configuration for selected NetLocal services
- [ ] Document I2P eepsite setup and key generation for anonymous local services
- [ ] Add onion address registration to the DNS registry for `.onion` name resolution
- [ ] Document security considerations and isolation requirements for dark net services

## Outline

The underground/dark net extension enables NetLocal services to be accessible via anonymizing overlay networks such as Tor and I2P, for privacy-preserving access and censorship resistance.

- Tor hidden services (`.onion`) expose selected internal services via the Tor network without revealing the server IP
- I2P eepsites provide an alternative anonymous overlay for services that need I2P reachability
- Onion addresses are published to the DNS registry so internal clients can resolve `.onion` names via CoreDNS
- Isolation: dark net containers run in a dedicated network segment separated from the main `localnet_default` to limit exposure
- TLS from Step-CA is still applied to hidden service traffic for end-to-end encryption within the Tor circuit
- Status: experimental — intended for privacy research and testing; review legal requirements before enabling in production
