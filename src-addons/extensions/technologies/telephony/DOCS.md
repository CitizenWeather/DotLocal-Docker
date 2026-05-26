# Telephony (VoIP & SIP)

## TODO

- [ ] Deploy FreeSWITCH or Asterisk as the PBX implementation and document dial plan configuration
- [ ] Configure SIP TLS and SRTP for encrypted voice calls using Step-CA certificates
- [ ] Add SIP trunk configuration for PSTN connectivity via a SIP provider
- [ ] Export call detail records (CDR) and active call metrics to the observability stack

## Outline

The telephony extension provides VoIP and SIP-based telephone services within the NetLocal environment using a self-hosted PBX server.

- FreeSWITCH or Asterisk serve as the PBX, handling SIP registration, call routing, and voicemail
- SIP clients (softphones, desk phones, mobile apps) register to `sip.<ROOT_DOMAIN>` using SIP over TLS (port 5061)
- SRTP encrypts voice media streams; TLS certificates are issued by Step-CA and trusted by SIP clients
- Dial plan routes internal extensions (e.g., 1xx), conference rooms, and PSTN calls via a SIP trunk
- Integrates with the IAM subsystem for user-extension mapping and authentication
- Voicemail and call recordings are stored in the object storage slot (MinIO)
