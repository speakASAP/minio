# CP-TASK-004: Protected Admin Wrapper

```yaml
id: CP-TASK-004
status: draft
owner: minio-service-owner
created: 2026-06-15
last_updated: 2026-06-15
source_task: ../11_tasks/TASK-004-protected-admin-wrapper.md
```

## Target task
TASK-004: `../11_tasks/TASK-004-protected-admin-wrapper.md`

## Upstream traceability
- Vision: `../01_vision/VISION.md`
- System: `../04_systems/SYS-001-private-object-storage.md`
- Feature: `../10_features/FEAT-005-protected-admin-wrapper.md`
- Goal impact: `../22_goal_impact/GOAL-IMPACT-TASK-004.md`
- Execution plan: `../21_execution_plans/EP-TASK-004-protected-admin-wrapper.md`

## Included documents
`README.md`, `17_governance/PROJECT_INVARIANTS.md`, `10_features/FEAT-004-customer-web-surface.md`, `web/app.js`, `web/admin.html`, and Kubernetes web manifests.

## Excluded documents
`.env*`, secret-bearing files, production object bodies, raw access tokens, authorization headers, and private presigned URLs.

## Constraints
Preserve `minio.alfares.cz` S3 root behavior. Expose only read-only metadata through an Auth-gated wrapper. Never return credentials or object bodies.

## Agent prompt
Use this package to maintain or validate the protected admin wrapper. Keep wrapper endpoints read-only unless a new traced task approves mutations.

## Validation instructions
Run Python and JavaScript syntax checks plus IPS gates. Runtime deployment requires a separate deploy and post-deploy health check.
