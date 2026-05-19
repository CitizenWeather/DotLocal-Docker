# NetLocal – Your Self-Contained Sub-Internet

NetLocal provides a complete, modular, local internet stack: DNS, CA, email, object storage, messaging, gateway, and ISP fabric – all inside Docker.

## Quick Start

```bash
git clone ... netlocal
cd netlocal
cp .env.example .env
# Edit .env to set your domain and secrets (minimal: change STALWART_SECRET, POWERDNS_API_KEY)
./scripts/bootstrap.sh
make up