# Goal Impact Mapping

```yaml
id: GOAL-IMPACT-MAPPING
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../01_vision/VISION.md
downstream:
  - ./GOAL-IMPACT-TASK-001.md
  - ./GOAL-IMPACT-TASK-002.md
related_adrs:
  - ADR-001
```

## Purpose
Ensure every MinIO artifact explains why it exists and links back to private object storage intent.

## Core principle
No production-affecting change proceeds unless it supports private, reliable S3-compatible storage or documented operational safety.

## Traceability chain
Vision / Business Goal -> System -> Feature -> Task -> Execution Plan -> Prompt -> Code Change -> Validation Report.

## Impact levels
Use critical, high, medium, low, or none with justification.

## Required fields for every goal impact record
Each record must include id, artifact type, artifact id, primary goal, impact level, description, success metric, upstream links, downstream links, validation method, and status.

## Orphan work rule
Work with no private-storage, reliability, security, or operational safety impact must be deferred or approved by a human owner.

## Agent behavior
If goal impact is missing, create a draft goal impact record or stop and mark the gap.

## Audit questions
Does the work preserve private object storage, protect credentials, preserve SigV4 behavior, and include validation evidence?
