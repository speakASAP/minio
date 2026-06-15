# TASK-003: Customer Web Surface

```yaml
id: TASK-003
status: completed
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../10_features/FEAT-004-customer-web-surface.md
goal_impact:
  - ../22_goal_impact/GOAL-IMPACT-TASK-003.md
execution_plan:
  - ../21_execution_plans/EP-TASK-003-customer-web-surface.md
```

## Objective
Implement the first customer web surface for MinIO: conversion landing page, Leads intake, Auth registration/login handoff, customer dashboard, and administrator dashboard shell.

## Upstream Links
- `../00_constitution/CONSTITUTION.md`
- `../01_vision/VISION.md`
- `../02_business_case/BUSINESS_CASE.md`
- `../04_systems/SYS-001-private-object-storage.md`
- `../10_features/FEAT-004-customer-web-surface.md`

## Goal Impact
This task increases conversion and onboarding clarity while preserving private storage boundaries. See `../22_goal_impact/GOAL-IMPACT-TASK-003.md`.

## Project Invariant Impact
Applies MINIO-INV-001 through MINIO-INV-009. The implementation preserves private buckets, presigned access boundaries, S3 SigV4 root behavior, and no committed credentials.

## Sensitive-Data Classification
Classification: synthetic. UI examples use synthetic metrics and masked connection details. No MinIO root credentials, access tokens, customer object names, or production logs are committed.

## Contract/Schema Impact
Uses existing Leads submit endpoint and Auth login/register/validate contracts. Does not change MinIO S3 API contracts.

## Replay/Determinism Impact
Static rendering is deterministic. Lead submission and Auth validation depend on external services and are tested as integration paths.

## Scope
- Static web UI in `web/`.
- Kubernetes static web deployment manifests under `k8s/web/`.
- Documentation and validation evidence for the first implementation.

## Non-Goals
- Do not expose real object inventory from browser code.
- Do not issue MinIO credentials from static JavaScript.
- Do not route web HTML from the S3 host root.

## Acceptance Criteria
- [x] Landing page includes pricing and conversion CTA.
- [x] Lead form submits the Leads contract with consent evidence only when checked.
- [x] Registration/login redirect to central Auth with `client_id=minio-microservice`.
- [x] Client dashboard allows local application onboarding drafts and shows S3 connection parameters without secrets.
- [x] Admin dashboard content is hidden until Auth validation returns an accepted administrator role.
- [x] S3 root endpoint behavior is not replaced by web HTML.

## Required Context
- `README.md`
- `17_governance/PROJECT_INVARIANTS.md`
- `23_documentation_contracts/SENSITIVE_DATA_POLICY.md`
- Auth and Leads contracts discovered from their remote repositories.

## Validation Task
Run static file checks, IPS gates, sensitive-data scan, and responsive browser rendering. Deployment requires separate host exposure for the web surface.

## Required Gates
- Pre-coding gate.
- Deployment-readiness gate before release.
- Static JS syntax check.

## Execution Plan Requirement
This task is implemented from `../21_execution_plans/EP-TASK-003-customer-web-surface.md`.
