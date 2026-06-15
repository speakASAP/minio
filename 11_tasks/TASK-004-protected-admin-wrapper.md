# TASK-004: Protected Admin Wrapper

```yaml
id: TASK-004
status: implemented
owner: minio-service-owner
created: 2026-06-15
last_updated: 2026-06-15
completeness_level: partial
upstream:
  - ../10_features/FEAT-005-protected-admin-wrapper.md
goal_impact:
  - ../22_goal_impact/GOAL-IMPACT-TASK-004.md
execution_plan:
  - ../21_execution_plans/EP-TASK-004-protected-admin-wrapper.md
```

## Objective
Implement the first protected backend wrapper for the MinIO admin web surface: read-only health, storage summary, and object metadata listing behind Auth administrator validation.

## Upstream Links
- `../01_vision/VISION.md`
- `../04_systems/SYS-001-private-object-storage.md`
- `../10_features/FEAT-004-customer-web-surface.md`
- `../10_features/FEAT-005-protected-admin-wrapper.md`

## Goal Impact
Allows administrators to inspect real storage metadata while preserving private buckets, credential secrecy, and the S3 endpoint boundary.

## Scope
- Add a dependency-free Python wrapper API under `backend/`.
- Add Kubernetes admin-api deployment and service manifests.
- Route `storage.alfares.cz/api/admin/*` to the wrapper without changing `minio.alfares.cz`.
- Update the admin UI to load protected metadata after Auth role validation.
- Record validation evidence and traceability.

## Non-Goals
- Bucket creation, deletion, policy mutation, credential issuance, object body streaming, customer self-service provisioning, or returning presigned private URLs.

## Acceptance Criteria
- [x] Protected endpoints require a Bearer token and administrator role.
- [x] the health endpoint is public and safe for probes.
- [x] the admin summary endpoint returns bucket-level metadata only.
- [x] the admin object-list endpoint returns bounded object metadata only.
- [x] Admin UI no longer labels object inventory as mock data after validation.
- [x] Deployment manifests mount records read-only.

## Required Context
`README.md`, `17_governance/PROJECT_INVARIANTS.md`, `10_features/FEAT-004-customer-web-surface.md`, and the Auth validation role contract used by the existing web UI.

## Validation Task
Validation evidence is recorded in `../12_validation/VAL-TASK-004-protected-admin-wrapper.md`.

## Execution Plan Requirement
Implementation follows `../21_execution_plans/EP-TASK-004-protected-admin-wrapper.md`.
