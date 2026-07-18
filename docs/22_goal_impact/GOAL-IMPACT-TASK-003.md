# GOAL-IMPACT-TASK-003: Customer Web Surface

```yaml
id: GOAL-IMPACT-TASK-003
artifact_type: goal_impact
artifact_id: TASK-003
artifact_path: ../11_tasks/TASK-003-customer-web-surface.md
primary_goal: GOAL-PRIVATE-STORAGE
impact_level: high
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
upstream_links:
  - ../01_vision/VISION.md
  - ../02_business_case/BUSINESS_CASE.md
  - ../10_features/FEAT-004-customer-web-surface.md
```

## Explanation
The customer web surface turns the MinIO service from an internal storage runtime into a visible product surface while preserving the original private-object-storage intent. Leads handles prospect intake, Auth handles user identity, and MinIO remains a private S3-compatible storage endpoint.

## Evidence
- Landing, pricing, registration, client, and admin sections are implemented in `../web/`.
- Separate static web manifests are implemented in `../k8s/web/`.
- README states that `minio.alfares.cz` remains the S3 API root and the web UI is served separately.
- Admin UI hides operational data until Auth role validation returns an accepted MinIO administrator role.

## Validation
Validate with static JS syntax check, IPS gates, browser rendering, and sensitive-data scan. Privileged object inventory and mutations are deferred until a protected backend wrapper exists.
