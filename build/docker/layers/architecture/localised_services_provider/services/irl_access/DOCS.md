# In-Real-Life (IRL) Access Control

## TODO

- [ ] Define supported physical access hardware (RFID readers, door controllers, badge scanners)
- [ ] Integrate IRL access with the local identity LDAP directory for user authentication
- [ ] Document API integration with physical access controllers (e.g., Lenel, HID, open-source alternatives)
- [ ] Add access event logging to Loki for audit trail and compliance

## Outline

The IRL access control service bridges the digital NetLocal identity infrastructure with physical access control systems such as door locks, badge readers, and entry gates.

- Authenticates physical access attempts against the local identity LDAP directory
- Supports RFID/NFC badges, PIN codes, and mobile app credentials linked to LDAP user accounts
- Access events (entry granted, denied, door forced) are published to the event bus and forwarded to Loki
- Integrates with the IoT extension (`iot` profile) for MQTT-based communication with physical controllers
- Access schedules and permissions are managed via the IAM subsystem with time-based rules
- Status: experimental — depends on the IoT extension and physical hardware integration
