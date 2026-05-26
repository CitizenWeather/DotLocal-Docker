# GCP Local Emulator

## TODO

- [ ] Document which GCP services are emulated (Pub/Sub, Firestore, Bigtable, Cloud Storage)
- [ ] Configure the GCP emulator endpoints in the gateway for TLS access
- [ ] Create initialization scripts for pre-populating Pub/Sub topics and Firestore collections
- [ ] Add GCP emulator health checks to `scripts/healthcheck.py`

## Outline

The GCP local emulator provides containerized emulators for Google Cloud Platform services, enabling offline development and testing of GCP-dependent applications.

- Covers GCP emulators: Pub/Sub emulator, Datastore/Firestore emulator, Bigtable emulator, and Cloud Storage (via fake-gcs-server)
- Each emulator runs as a separate container and exposes the standard GCP SDK gRPC/HTTP endpoint
- Configure GCP SDKs to use `PUBSUB_EMULATOR_HOST`, `DATASTORE_EMULATOR_HOST`, etc. environment variables
- Accessible through the gateway at `gcp-<service>.<ROOT_DOMAIN>` with TLS from Step-CA
- Part of the faux provider collection under `apps/faux_provider/cloud_local/`; requires manual compose inclusion
- Status: available as a faux provider; emulator coverage is incomplete — Pub/Sub and Datastore are highest priority
