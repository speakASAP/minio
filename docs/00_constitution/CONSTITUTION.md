# Project Constitution

```yaml
id: CONSTITUTION
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream: []
downstream:
  - ../01_vision/VISION.md
  - ../17_governance/PROJECT_INVARIANTS.md
related_adrs:
  - ADR-001
```

## Purpose
Protect the original intent of minio-microservice: private S3-compatible object storage for lesson recordings and service artifacts.

## Constitutional Principles
- Preserve private storage intent through documentation, deployment, and validation.
- Treat this constitution and the vision as protected after bootstrap.
- Require traceability from business need to task, execution plan, and validation evidence before future implementation work.
- Keep storage credentials, access keys, secret keys, authorization headers, and production object data out of prompts, tests, examples, reports, logs, and committed files.
- Keep buckets private; anonymous read access is forbidden.
- Preserve the documented object-key contract for lesson recordings unless a human-approved ADR changes it.
- Validate proxy behavior for S3 SigV4 before production-affecting deployment changes.

## Amendment Process
Changes require a human-approved amendment under ../17_governance/amendments/ and downstream validation.

## AI Agent Rules
AI agents may read and reference this document but must not modify it after bootstrap without explicit owner instruction.

## Change Note
- 2026-06-13: Initial constitution created during IPS bootstrap.
