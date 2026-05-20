# Future Extensions

## 1. Multi-host federation
Your Swarm capability hints at this. Push it further:

- Two localnets on different physical hosts can peer like real ASes
- BGP simulation between them (FRR / BIRD in containers)
- Models real internet topology: backbones, peering, transit, CDN edge
- Suddenly localnet is teaching internet engineering, not just hosting services