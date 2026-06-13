# Change Control

```yaml
id: CHANGE-CONTROL
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../00_constitution/CONSTITUTION.md
  - ../01_vision/VISION.md
downstream: []
related_adrs:
  - ADR-001
```

## Protected documents
00_constitution/CONSTITUTION.md and 01_vision/VISION.md.

## Change categories
### Minor documentation change
Clarifies existing behavior without changing storage intent, access policy, deployment behavior, or consumer contracts.

### Major documentation change
Changes architecture, access boundary, bucket policy, consumer contract, or deployment expectations. Requires task, plan, ADR when architectural, and validation report.

### Vision amendment
Changes original intent or non-goals. Requires human approval through amendments and downstream updates.

## Approval rules
Draft AI-created documents require human owner review before approved or validated status.

## AI role
AI may draft mutable docs, propose amendments, and run gates. AI must not invent approval or weaken invariants.
