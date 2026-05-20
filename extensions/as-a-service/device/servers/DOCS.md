# Device Server Emulation

## TODO

- [ ] Define device types to emulate (SNMP agents, Modbus devices, BACnet controllers)
- [ ] Create a configurable virtual SNMP agent for network device simulation
- [ ] Document how to add new device profiles using templated configuration files
- [ ] Integrate device emulator telemetry with Prometheus for monitoring lab scenarios

## Outline

Device server emulation provides simulated network-attached devices for testing device management, monitoring, and automation workflows in the NetLocal lab environment.

- Emulates network devices such as routers, switches, IoT controllers, and industrial equipment via protocol-level simulation
- SNMP agent emulators respond to SNMP GET/SET/TRAP operations as if from real managed devices
- Modbus TCP and BACnet/IP emulators support industrial automation and building management system testing
- Device profiles (OID trees, register maps) are defined in config files and loaded at container startup
- Integrates with the observability stack — Prometheus SNMP exporter can scrape emulated device metrics
- Status: experimental — initial SNMP device emulation is the planned first implementation
