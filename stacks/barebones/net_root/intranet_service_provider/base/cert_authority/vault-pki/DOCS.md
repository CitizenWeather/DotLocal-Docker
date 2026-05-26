# vault-pki CA slot

Slot path: `stacks/barebones/net_root/intranet_service_provider/base/cert_authority/vault-pki/`

To activate: set `CA_APP=vault-pki` in `.env`.

Image: `hashicorp/vault:latest`
Backbone IP: `169.254.0.4`
Vault PKI secrets engine must be enabled and configured after first start.
