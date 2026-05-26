# AWS LocalStack Emulator

## TODO

- [ ] Document which AWS services are enabled in the LocalStack compose configuration
- [ ] Add `aws` CLI profile configuration pointing to `http://localstack.<ROOT_DOMAIN>:4566`
- [ ] Create initialization scripts that pre-populate S3 buckets, SQS queues, and DynamoDB tables
- [ ] Add LocalStack health endpoint to `scripts/healthcheck.py`

## Outline

LocalStack provides a local emulator for AWS cloud services, enabling development and testing of AWS-dependent applications without internet access or AWS accounts.

- Emulates core AWS services: S3, SQS, SNS, DynamoDB, Lambda, IAM, Secrets Manager, and more
- Accessible at `http://localstack.<ROOT_DOMAIN>:4566`; configure the AWS SDK with `endpoint_url` pointing here
- Initialized with pre-created resources via `docker-compose.yml` init scripts or the LocalStack `init-hooks` mechanism
- Integrates with the gateway for TLS-terminated access at `https://localstack.<ROOT_DOMAIN>`
- Works alongside the object storage slot (MinIO) — use LocalStack S3 for AWS-SDK compatibility, MinIO for S3-protocol storage
- Status: available as a faux provider under `apps/faux_provider/cloud_local/`; activation requires manual compose inclusion
