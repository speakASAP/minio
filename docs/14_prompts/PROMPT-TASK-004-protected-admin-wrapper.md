# PROMPT-TASK-004: Protected Admin Wrapper

```yaml
id: PROMPT-TASK-004
status: completed
owner: minio-service-owner
created: 2026-06-15
last_updated: 2026-06-15
source_execution_plan: ../21_execution_plans/EP-TASK-004-protected-admin-wrapper.md
context_package: ../13_context_packages/CP-TASK-004-protected-admin-wrapper.md
```

## Role
You are a backend, platform, and frontend integration engineer implementing a protected read-only admin wrapper for MinIO metadata.

## Task
Add the first backend wrapper slice for the MinIO admin web surface and wire the admin UI to it after Auth administrator validation.

## Context
The static admin dashboard intentionally avoided real object inventory because browser code must not expose MinIO credentials. The wrapper creates a server-side read-only boundary under the storage host admin API route.

## Constraints
- Do not modify `.env*` or secret files.
- Do not expose credentials, authorization headers, object bodies, raw production data in docs, or full private presigned URLs.
- Do not change `minio.alfares.cz` S3 root behavior.
- Do not add bucket mutation or credential issuance in this slice.

## Acceptance criteria
- Wrapper exposes the health endpoint, the admin summary endpoint, and the admin object-list endpoint.
- Protected endpoints require Auth administrator role validation.
- Admin UI loads real metadata only after admin role validation.
- Kubernetes manifests mount records read-only.
- Syntax checks and IPS gates pass or deviations are documented.

## Validation
Run:

```bash
python3 -m py_compile backend/wrapper_api.py
node --check web/app.js
python3 scripts/pre_coding_gate.py --root .
python3 scripts/deployment_readiness_gate.py --root . --target TASK-004
```
