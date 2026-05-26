# LoRaWAN IoT Networking

## TODO

- [ ] Document ChirpStack network server and application server configuration
- [ ] Add LoRa gateway bridge configuration for connecting physical LoRa gateways
- [ ] Create device profile templates for common LoRaWAN Class A/B/C device types
- [ ] Export ChirpStack device metrics to Prometheus for Grafana visualization

## Outline

The LoRaWAN extension provides a complete LoRa network server stack using ChirpStack for connecting and managing LoRaWAN IoT devices within the NetLocal environment.

- Activated via the `iot` extension tag in `EXTENSION_TAGS`; includes ChirpStack Network Server, Application Server, and Gateway Bridge
- ChirpStack provides OTAA/ABP device activation, ADR (Adaptive Data Rate), and multi-gateway diversity
- LoRa Gateway Bridge converts Semtech UDP packet-forwarder protocol from physical gateways to MQTT
- Device payloads are published to the MQTT broker (Eclipse Mosquitto, also in the IoT extension) for downstream processing
- Integrates with the data streams extension for routing LoRaWAN telemetry into the data lake
- Accessible at `chirpstack.<ROOT_DOMAIN>` through the gateway; MQTT broker at `mqtt.<ROOT_DOMAIN>:1883`
