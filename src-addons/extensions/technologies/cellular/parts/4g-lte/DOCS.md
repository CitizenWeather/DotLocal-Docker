# 4G/LTE Simulation

## TODO

- [ ] Deploy Open5GS or srsRAN for 4G LTE core network simulation
- [ ] Document EPC component configuration (MME, SGW, PGW, HSS)
- [ ] Configure the simulated LTE RAN to connect to physical or virtual UE devices
- [ ] Add LTE core metrics (attached UEs, data throughput) to Grafana dashboards

## Outline

The 4G/LTE simulation extension provides a containerized LTE (Long-Term Evolution) network stack for testing mobile network protocols and LTE-connected device integrations.

- Uses Open5GS or srsRAN to implement the full LTE Evolved Packet Core (EPC): MME, SGW, PGW, and HSS components
- Simulated UE (User Equipment) devices connect to the virtual RAN (srsRAN) and authenticate against the HSS
- The PDN Gateway (PGW) bridges LTE data sessions to the `localnet_default` network for internet access
- Enables testing of LTE-dependent IoT devices, mobile application behavior, and core network configuration
- Integrates with the LoRaWAN extension for multi-RAT IoT lab scenarios
- Status: experimental — requires host kernel support for TUN/TAP interfaces and significant CPU/memory resources
