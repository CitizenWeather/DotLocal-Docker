# Security Lab Build Profiles

## TODO

- [ ] Define security lab profiles: `pentest`, `threat-modeling`, `vuln-scan`, `network-analysis`
- [ ] Document which tools are included in each profile and their intended use cases
- [ ] Add network isolation for security lab containers to prevent accidental attacks on production services
- [ ] Document legal and ethical use guidelines for security tools in the lab

## Outline

Security lab build profiles define curated sets of security tools and configurations for penetration testing, vulnerability scanning, and network analysis within the NetLocal environment.

- Each profile activates a specific combination of security tools as Docker Compose services with appropriate profiles tags
- `pentest` profile includes tools like Metasploit, Burp Suite Community, and Nmap for offensive security testing
- `vuln-scan` profile deploys OpenVAS/Greenbone for automated vulnerability scanning of local network services
- `network-analysis` profile includes Wireshark (headless), Zeek, and Suricata for passive network monitoring
- Security lab containers are isolated in a dedicated Docker network to prevent accidental impact on production services
- Status: experimental — tool licensing and resource requirements vary; review each tool's license before use
