# Roadmap

```yaml
id: ROADMAP
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../01_vision/VISION.md
downstream:
  - ../09_milestones/MS-001-ips-foundation.md
  - ../09_milestones/MS-002-access-policy-review.md
  - ../09_milestones/MS-003-operational-readiness.md
related_adrs:
  - ADR-001
```

## Phase 1: IPS Foundation
Create the IPS documentation structure, project docs, templates, gates, and validation evidence.

## Phase 2: Access Policy Review
Review presigned URL TTL, bucket privacy, CORS behavior, and consumer configuration.

## Phase 3: Operational Readiness
Keep diagnostics, deployment docs, and signature tests current with runtime deployment changes.

## Phase 4: Consumer Alignment
When consumer behavior changes, update MinIO contracts and validation with the owning consumer service.
