# Validation Pyramid

```yaml
id: VALIDATION-PYRAMID
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../01_vision/VISION.md
downstream:
  - ./VAL-TASK-001-ips-documentation-bootstrap.md
related_adrs:
  - ADR-001
```

## Purpose
Define how MinIO work is validated from documentation to runtime behavior.

## Levels
1. Documentation gates.
2. Configuration checks.
3. Runtime health checks.
4. S3 behavior checks.
5. Consumer evidence owned by consumer services.

## Required Evidence
Validation reports must summarize commands, status, and safe evidence without secrets, authorization headers, raw production object data, or full presigned URLs.
