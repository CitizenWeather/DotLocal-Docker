# 5G Simulation

## TODO

- [ ] Deploy Open5GS 5G SA core (AMF, SMF, UPF, NRF, AUSF, UDM) in containers
- [ ] Document the 5G standalone architecture component roles and inter-NF communication (SBA)
- [ ] Configure a simulated gNB (gNodeB) using srsRAN 5G for RAN simulation
- [ ] Add 5G core KPIs (PDU session establishment rate, handover success rate) to Grafana

## Outline

The 5G simulation extension provides a containerized 5G Standalone (SA) core network for testing 5G protocol stacks, network slicing, and 5G-connected device behavior.

- Uses Open5GS 5G SA core implementing the full 3GPP Rel-15 network functions: AMF, SMF, UPF, NRF, AUSF, UDM, PCF
- Service-Based Architecture (SBA) enables NF-to-NF communication via HTTP/2 over the backbone network
- srsRAN 5G simulates the gNB (next-generation NodeB) and connects UE simulators to the 5G core
- Network slicing support allows multiple virtual 5G networks over the same infrastructure
- Integrates with the 4G/LTE simulation for NSA (Non-Standalone) dual-connectivity scenarios
- Status: experimental — 5G simulation has high CPU requirements; dedicated hardware or a powerful VM is recommended
