# EP-TASK-004: Protected Admin Wrapper

```yaml
id: EP-TASK-004
status: implemented
source_task: ../11_tasks/TASK-004-protected-admin-wrapper.md
owner: minio-service-owner
created: 2026-06-15
last_updated: 2026-06-15
completeness_level: partial
vision: ../01_vision/VISION.md
constitution: ../00_constitution/CONSTITUTION.md
feature: ../10_features/FEAT-005-protected-admin-wrapper.md
goal_impact: ../22_goal_impact/GOAL-IMPACT-TASK-004.md
```

## Metadata
Task TASK-004; lifecycle state implemented for the read-only backend-wrapper slice.

## Upstream Traceability
Vision, private object storage system, customer web surface feature, protected wrapper feature, goal impact, coding prompt, code, and validation report are linked in the graph.

## Goal Impact
Improves operational visibility while keeping credentials, object bodies, private URLs, and bucket mutations outside browser reach.

## Scope
Read-only protected wrapper API, Kubernetes deployment/service, web ingress route, admin UI integration, docs, and validation evidence.

## Non-Goals
Credential issuance, bucket mutation, object deletion, object upload, object body download, presigned URL generation, or customer self-service provisioning.

## Files to Inspect
`web/app.js`, `web/admin.html`, `k8s/web/ingress.yaml`, `scripts/deploy.sh`, `README.md`, and project invariants.

## Files to Create
`backend/wrapper_api.py`, `k8s/admin-api/deployment.yaml`, `k8s/admin-api/service.yaml`, TASK-004 IPS artifacts, and validation report.

## Files to Modify
`web/app.js`, `web/admin.html`, `k8s/web/configmap.yaml`, `k8s/web/ingress.yaml`, `scripts/deploy.sh`, `README.md`, and graph files.

## Files That Must Not Be Modified
`.env*`, secret files, immutable vision/constitution files, MinIO S3 root ingress behavior for `minio.alfares.cz`, and production object data.

## Implementation Steps
1. Add a minimal wrapper API with public `/healthz` and protected `/api/admin/*` endpoints.
2. Validate Auth bearer tokens through the Auth validation endpoint and require accepted admin roles.
3. Read metadata from the mounted records bucket without reading object bodies.
4. Add Kubernetes deployment/service and route the admin API route on the web host to the wrapper.
5. Update admin UI to load protected metadata after administrator validation.
6. Run syntax checks and IPS gates.

## Parallel Execution

Status: implemented as one integration slice because source, deployment, and UI contracts are tightly coupled.

| Workstream | State | Owner role | Objective | Scope | Allowed files | Forbidden files | Dependencies | Validation evidence | Handoff notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TASK-004-A Wrapper API | completed | Backend engineer | Implement read-only Auth-gated metadata endpoints. | `backend/`, `k8s/admin-api/` | `backend/wrapper_api.py`, admin API manifests | `.env*`, object data, S3 root ingress | Auth role contract | `python3 -m py_compile backend/wrapper_api.py` | Keep mutations out of scope. |
| TASK-004-B Admin UI | completed | Frontend engineer | Replace mock inventory with protected API calls. | `web/` | `web/app.js`, `web/admin.html`, generated web ConfigMap | Credentials, raw tokens in UI, object bodies | TASK-004-A endpoint contract | `node --check web/app.js` | Admin data remains hidden until Auth role validation passes. |
| TASK-004-C Platform route | completed | Platform engineer | Expose wrapper under the storage host admin API route. | `k8s/`, `scripts/deploy.sh` | admin API manifests, web ingress, deploy script | `minio.alfares.cz` S3 root semantics | TASK-004-A service name | IPS deployment gate | Route order keeps the admin API route before `/`. |
| TASK-004-D Documentation and validation | completed | Validation engineer | Update IPS chain and safe evidence. | IPS docs, graph, README | TASK/EP/CP/PROMPT/VAL/GOAL docs and graph | Secrets and production data | A-C outputs | pre-coding and deployment-readiness gates | Mark missing runtime deployment evidence honestly. |
| TASK-004-E Final integration | final integration | minio-service-owner | Review combined behavior and decide release. | All changed files | Files changed by A-D | unrelated files | A-D complete | final command summary | Deployment is separate from implementation validation. |

Shared files/contracts: Auth role contract, the storage host admin API route route, read-only object metadata response shape. Integration owner: `minio-service-owner`. Validation owner: TASK-004-D. Merge order: Wrapper API, platform route, UI wiring, docs/evidence, final validation.

## Test Plan
Run Python syntax check, JavaScript syntax check, unauthenticated endpoint behavior check where possible, pre-coding gate, and deployment-readiness gate.

## Validation Plan
Record command results in `../12_validation/VAL-TASK-004-protected-admin-wrapper.md`. Runtime deployment validation remains required after `./scripts/deploy.sh`.

## Documentation Updates
Update README customer web surface/admin wrapper sections, graph nodes/edges, and TASK-004 artifacts.

## Rollback Plan
Remove `backend/wrapper_api.py`, `k8s/admin-api/`, the admin API route ingress route, deploy script admin-api apply block, admin UI API calls, and TASK-004 documentation artifacts.

## Agent Handoff Prompt
Implement only the read-only protected admin wrapper. Preserve private bucket behavior, credential secrecy, S3 root semantics, and Auth administrator role gating. Do not implement credential issuance or mutations.

## Completion Checklist
- [x] Implementation complete for read-only wrapper slice
- [x] Tests complete for syntax and documentation gates
- [x] Validation evidence collected
- [x] Documentation updated
- [x] Deviations documented
