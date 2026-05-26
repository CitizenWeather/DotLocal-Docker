# Software-Defined Radio (SDR)

## TODO

- [ ] Deploy GNU Radio or SDR# in a containerized environment with device passthrough
- [ ] Document USB passthrough configuration for RTL-SDR and HackRF devices
- [ ] Create example GNU Radio flowgraphs for common protocols (FM, ADS-B, APRS)
- [ ] Add SDR processing pipeline metrics to the observability stack

## Outline

The SDR extension provides software-defined radio processing capabilities within the NetLocal lab, enabling reception and analysis of radio frequency signals using containerized radio software.

- Supports common SDR hardware via USB passthrough: RTL-SDR (receive only), HackRF One (TX/RX), USRP
- GNU Radio Companion runs headless in a container with flowgraphs loaded from `config/radio/flowgraphs/`
- Common use cases: ADS-B aircraft tracking, weather satellite imagery, APRS packet radio, FM spectrum monitoring
- Decoded signal data can be published to the MQTT broker (IoT extension) or the event bus for downstream processing
- Integrates with the telephony extension for analyzing RF signals related to VoIP and cellular protocols
- Status: experimental — requires USB device passthrough and SDR hardware; host kernel must support libusb access
