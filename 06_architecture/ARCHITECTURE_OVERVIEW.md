# Architecture Overview

```yaml
id: ARCHITECTURE-OVERVIEW
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../01_vision/VISION.md
  - ../04_systems/SYS-001-private-object-storage.md
downstream:
  - ../07_decisions/ADR-001-adopt-intent-preservation-system.md
related_adrs:
  - ADR-001
```

## Architectural style
Infrastructure service wrapping MinIO with deployment, proxy, bucket initialization, CORS, and diagnostic scripts.

## Runtime components
MinIO S3 API, private bucket, Nginx public endpoint, secret-backed environment configuration, shell diagnostics, and Python signature tests.

## Storage choices
MinIO persists objects and metadata under the configured host data root. Bucket directories and metadata must live on a compatible filesystem layout.

## Access model
Consumers authenticate writes with credentials. Browser and playback access use presigned URLs only. Anonymous bucket read is forbidden.

## Proxy model
The public endpoint must preserve S3 SigV4 host, path, authorization, and method behavior.

## Security model
Secrets live in environment or secret management, not in Git or IPS artifacts.

## Validation model
Use IPS gates for documentation readiness, service scripts for runtime health, and S3 signature tests for public endpoint correctness.
