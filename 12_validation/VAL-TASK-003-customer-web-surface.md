# VAL-TASK-003: Customer Web Surface Validation

```yaml
id: VAL-TASK-003
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
source_task: ../11_tasks/TASK-003-customer-web-surface.md
```

## Summary
Initial customer web surface implemented as static browser-safe UI with Leads intake, Auth handoff, customer dashboard, administrator dashboard shell, and separate static web deployment manifests.

## Upstream goal
Support the MinIO private-object-storage goal by improving customer conversion and onboarding without weakening private bucket, presigned URL, or S3 SigV4 constraints.

## Criteria checked
- Landing and pricing are present.
- Lead form uses Leads contract fields and consent evidence only when checked.
- Auth registration/login handoff uses `client_id=minio-microservice`.
- Customer dashboard stores application onboarding drafts locally and shows no secrets.
- Admin panel hides data until an accepted administrator role is validated.
- Static web deployment is separate from the S3 API host root.

## Issues found
- Real object inventory, real bucket mutation, credential issuance, and storage metrics require a backend wrapper and are intentionally not implemented in browser-only static UI.
- Deployment-readiness depends on repository-wide IPS audit passing and final host/DNS readiness for `storage.alfares.cz`.

## Recommendation
Proceed with static web deployment after final operator review. Plan a follow-up backend-wrapper task for protected object inventory, usage metrics, credential issuance, and settings mutations.

## Traceability confirmation
Validated against `../10_features/FEAT-004-customer-web-surface.md`, `../11_tasks/TASK-003-customer-web-surface.md`, `../21_execution_plans/EP-TASK-003-customer-web-surface.md`, and `../22_goal_impact/GOAL-IMPACT-TASK-003.md`.
