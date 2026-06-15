# TASK-002: Review Presigned URL TTL Settings

```yaml
id: TASK-002
status: reviewed
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: partial
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
Potential configuration contract impact if TTL values or consumer environment expectations change. No MinIO-side contract or runtime behavior was changed during this review.

## Replay/Determinism Impact
Validation should be repeatable with synthetic object keys and non-secret summaries.

## Scope
Identify current TTL expectations, confirm the owning consumer/configuration, decide whether updates are needed, and validate any changed behavior. This review confirmed the documented owner boundary but not the external production config value.

## Non-Goals
Anonymous reads, bucket policy relaxation, unrelated proxy changes, or consumer repository edits without separate approval.

## Acceptance Criteria
- [x] TTL owner boundary and expected maximum are documented.
- [x] No secrets or raw presigned production URLs appear in reports.
- [x] No configuration change was made; validation evidence documents that runtime behavior is unchanged.
- [x] External consumer-side production TTL verification is documented as deferred follow-up, outside this MinIO-side review scope.

## Integrated Parallel Review Findings
- TASK-002-A completed TTL source discovery and found `[MISSING: effective TTL source]` in the allowed MinIO repository surfaces.
- TASK-002-B completed policy review and recommends preserving `<= 24 hours` as the hard cap, with `15-60 minutes` preferred for normal playback when regeneration is available.
- TASK-002-C completed validation readiness; documentation gates passed, while `scripts/test-s3-signature.sh` was not run because it requires credentials. `[MISSING: safe credentials/approval]`
- TASK-002-D integrated the findings into MinIO-side planning and validation docs without changing runtime behavior.

## Current Decision
No MinIO, nginx, bucket policy, or consumer runtime change is justified from the available MinIO-side evidence. The remaining work is external fact verification for the consumer-side TTL config key and effective production value.

## Missing External Facts
- `[MISSING: effective production TTL value in speakasap-portal configuration]`
- `[MISSING: effective TTL configured for runlayer artifact access, if runlayer generates presigned URLs]`
- `[MISSING: safe credentials/approval]` for SigV4 validation beyond documentation gates.

## Required Context
README.md, BUSINESS.md, FEAT-002, and PROJECT_INVARIANTS.

## Validation Task
Dedicated validation evidence is recorded in `../12_validation/VAL-TASK-002-review-presigned-url-ttl-settings.md`. Close the remaining external TTL-value gap only after approved consumer-side inspection.

## Required Gates
Pre-coding gate, deployment-readiness gate before deployment, and S3 signature test when endpoint behavior changes.

## Execution Plan Requirement
This task must not be converted into code until its execution plan is reviewed for the specific scope.
