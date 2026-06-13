# Business Case: minio-microservice

```yaml
id: BUSINESS-CASE
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../BUSINESS.md
  - ../README.md
downstream:
  - ../10_features/FEAT-001-private-recording-storage.md
  - ../10_features/FEAT-002-presigned-access-boundary.md
related_adrs:
  - ADR-001
```

## Problem
Lesson recordings and service artifacts need durable object storage without depending on shared filesystem mounts between consumer applications and the MinIO host.

## Pain Points
- Shared storage couples servers and operations.
- Browser playback requires public HTTPS reachability while storage remains private.
- SigV4 upload and download fail if proxies alter host, path, or authorization headers.
- Credential mistakes can expose storage or break uploads.

## Proposed Solution
Operate MinIO as the private S3-compatible backing store, expose it through the documented public endpoint, keep bucket access private, and require presigned URLs for reads.

## Value Proposition
Reliable storage, standard S3 APIs for consumers, repeatable diagnostics, and traceable future maintenance.

## Differentiators
Private-by-default storage, explicit lesson key layout, and operational scripts for MinIO, proxy, CORS, TLS, and SigV4 validation.

## Risks
Exposed credentials, accidental anonymous read policy, proxy signature breakage, and invalid cross-filesystem MinIO data layout.

## Adoption Strategy
Use existing root documentation and scripts as source material, add IPS traceability, and require gate evidence before production-affecting changes.
