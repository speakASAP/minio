# GOAL-IMPACT-TASK-004: Protected Admin Wrapper

```yaml
id: GOAL-IMPACT-TASK-004
artifact_type: goal_impact
artifact_id: TASK-004
artifact_path: ../11_tasks/TASK-004-protected-admin-wrapper.md
primary_goal: GOAL-PRIVATE-STORAGE
impact_level: high
status: draft
owner: minio-service-owner
created: 2026-06-15
last_updated: 2026-06-15
upstream_links:
  - ../01_vision/VISION.md
  - ../04_systems/SYS-001-private-object-storage.md
  - ../10_features/FEAT-005-protected-admin-wrapper.md
```

## Explanation
The protected admin wrapper allows operational visibility into real MinIO storage metadata while maintaining private bucket intent. It moves privileged metadata access out of static browser code and behind Auth administrator role validation.

## Evidence
- Read-only wrapper API is implemented in `../backend/wrapper_api.py`.
- Admin API Kubernetes manifests mount records read-only in `../k8s/admin-api/`.
- Web ingress routes the storage host admin API route to the wrapper without changing the S3 host root.
- Admin UI only loads metadata after accepted administrator role validation.

## Validation
Validated by `../12_validation/VAL-TASK-004-protected-admin-wrapper.md` with syntax checks and IPS gates. Runtime deployment validation remains a separate release action.
