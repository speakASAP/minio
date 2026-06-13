# TASK-002: Review Presigned URL TTL Settings

```yaml
id: TASK-002
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../09_milestones/MS-002-access-policy-review.md
  - ../10_features/FEAT-002-presigned-access-boundary.md
goal_impact:
  - ../22_goal_impact/GOAL-IMPACT-TASK-002.md
execution_plan:
  - ../21_execution_plans/EP-TASK-002-review-presigned-url-ttl-settings.md
```

## Objective
Review presigned URL TTL settings and document whether they remain appropriate for private lesson recording playback and artifact access.

## Upstream Links

- `../01_vision/VISION.md`
- `../10_features/FEAT-002-presigned-access-boundary.md`
- `../09_milestones/MS-002-access-policy-review.md`

## Goal Impact
Supports private object access by limiting exposure duration while preserving playback usability.

## Project Invariant Impact
Applies MINIO-INV-001, MINIO-INV-002, MINIO-INV-003, and MINIO-INV-007.

## Sensitive-Data Classification
Classification: none. Do not include actual secret values, authorization headers, or production presigned URLs.

## Contract/Schema Impact
Potential configuration contract impact if TTL values or consumer environment expectations change.

## Replay/Determinism Impact
Validation should be repeatable with synthetic object keys and non-secret summaries.

## Scope
Identify current TTL expectations, confirm the owning consumer/configuration, decide whether updates are needed, and validate any changed behavior.

## Non-Goals
Anonymous reads, bucket policy relaxation, unrelated proxy changes, or consumer repository edits without separate approval.

## Acceptance Criteria
- [ ] TTL owner and expected maximum are documented.
- [ ] No secrets or raw presigned production URLs appear in reports.
- [ ] Any configuration change has validation evidence.

## Required Context
README.md, BUSINESS.md, FEAT-002, and PROJECT_INVARIANTS.

## Validation Task
Create ../12_validation/VAL-TASK-002-review-presigned-url-ttl-settings.md before closing the task.

## Required Gates
Pre-coding gate, deployment-readiness gate before deployment, and S3 signature test when endpoint behavior changes.

## Execution Plan Requirement
This task must not be converted into code until its execution plan is reviewed for the specific scope.
