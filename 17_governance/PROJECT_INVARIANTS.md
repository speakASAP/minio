# Project Invariants

```yaml
id: PROJECT-INVARIANTS
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../00_constitution/CONSTITUTION.md
  - ../01_vision/VISION.md
downstream:
  - ../11_tasks/TASK-001-ips-documentation-bootstrap.md
  - ../11_tasks/TASK-002-review-presigned-url-ttl-settings.md
related_adrs:
  - ADR-001
```

## Purpose
Define non-negotiable MinIO service rules that future implementation and deployment work must preserve.

## Applicability
These invariants apply to documentation, scripts, configuration, deployment, proxy changes, and validation artifacts.

## Invariants
1. MINIO-INV-001: Bucket contents must remain private; anonymous read is forbidden.
2. MINIO-INV-002: Object reads use authenticated S3 calls or presigned URLs.
3. MINIO-INV-003: Credentials, authorization headers, and tokens must never appear in committed docs, prompts, examples, reports, screenshots, or logs.
4. MINIO-INV-004: Lesson recording keys preserve YYYY/MM/DD/lesson_<uuid>.mp3 unless an approved ADR changes it.
5. MINIO-INV-005: Proxy changes must preserve S3 SigV4 host, path, authorization, and method semantics.
6. MINIO-INV-006: MinIO metadata and bucket paths must avoid cross-device object move failures.
7. MINIO-INV-007: CORS and presigned URL behavior must support approved browser playback without public bucket policy.
8. MINIO-INV-008: Deployment-affecting changes require safe validation evidence.
9. MINIO-INV-009: AI-created docs must not be marked approved or validated without human review evidence.

## Exceptions
Exceptions require a traced task, execution plan, owner approval, and validation report.

## Review cadence
Review invariants during IPS audits and before production-affecting changes.
