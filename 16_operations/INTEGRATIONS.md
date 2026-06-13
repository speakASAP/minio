# Integrations

```yaml
id: INTEGRATIONS
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../04_systems/SYS-001-private-object-storage.md
downstream:
  - ../10_features/FEAT-002-presigned-access-boundary.md
related_adrs:
  - ADR-001
```

## Consumers
speakasap-portal uploads lesson MP3 recordings and serves playback through presigned GET URLs. runlayer stores task artifacts.

## Public endpoint
Production public endpoint is documented as https://minio.alfares.cz.

## Credentials
Credentials must be passed through environment or secret management and never quoted in docs, prompts, reports, examples, or logs.

## Proxy contract
Proxy routing must preserve S3 SigV4 host, path, authorization, and method handling.

## Validation
Use direct and public endpoint S3 signature tests after endpoint, proxy, bucket, CORS, or credential-routing changes.
