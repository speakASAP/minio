# Vision: minio-microservice

```yaml
id: VISION
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../BUSINESS.md
  - ../SYSTEM.md
  - ../README.md
downstream:
  - ../02_business_case/BUSINESS_CASE.md
  - ../04_systems/SYS-001-private-object-storage.md
related_adrs:
  - ADR-001
```

## One-Sentence Vision
Provide reliable private S3-compatible storage for lesson recordings and service artifacts, reachable through controlled MinIO endpoints and never through anonymous public bucket access.

## Problem Statement
The ecosystem needs durable object storage without NFS coupling between application servers. Consumers need S3 PUT, private storage, and presigned GET playback while MinIO remains protected.

## Target Users
- speakasap-portal, for lesson recording upload and playback.
- runlayer, for task artifact storage.
- Operators responsible for deployment, proxy routing, diagnostics, and bucket policy.

## Core User Need
Consumers need stable object storage with predictable key layout, credentials managed outside Git, private buckets, and presigned URL access through the public endpoint.

## Key Outcomes
- Lesson recordings use YYYY/MM/DD/lesson_<uuid>.mp3 keys.
- Bucket contents are private and served only through authenticated S3 operations or presigned URLs.
- Public endpoint and proxy behavior preserve S3 SigV4 signing requirements.
- Operators can diagnose bucket, proxy, CORS, certificate, and signature failures.
- No committed artifact exposes storage credentials or raw production objects.

## Non-Goals
- Public anonymous object hosting.
- Changing consumer upload or playback semantics without traced validation.
- Storing secrets in repository docs, examples, prompts, reports, or source files.

## Success Criteria
- scripts/test-s3-signature.sh passes direct and public PUT/GET checks when production dependencies are available.
- scripts/check-minio.sh confirms health, bucket access, and private policy expectations.
- Future implementation work has IPS task, execution plan, goal impact, gate, and validation evidence.

## Product Philosophy
MinIO is infrastructure: quiet, stable, private by default, and easy for operators to verify.

## AI Philosophy
AI assistance is allowed for bounded maintenance only when upstream intent, sensitive-data handling, and validation commands are explicit.


## Operational Constraints

The service must preserve the current operational model documented in the root README and system docs. MinIO remains the storage boundary for recordings and artifacts, while consumer services own business workflows. Production access uses the public MinIO endpoint when consumers are on different servers, and proxy routing must not alter signed S3 host, path, method, or authorization semantics. The records bucket must stay private, CORS must be limited to approved browser origins, and diagnostic evidence must summarize failures without copying credentials, authorization headers, raw object data, or full production presigned URLs. Deployment-affecting changes must update documentation and validation evidence together.
