# EP-TASK-003: Customer Web Surface

```yaml
id: EP-TASK-003
status: implemented
source_task: ../11_tasks/TASK-003-customer-web-surface.md
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
vision: ../01_vision/VISION.md
constitution: ../00_constitution/CONSTITUTION.md
feature: ../10_features/FEAT-004-customer-web-surface.md
goal_impact: ../22_goal_impact/GOAL-IMPACT-TASK-003.md
```

## Metadata
Owner: minio-service-owner. Lifecycle state: implemented. Source task: `../11_tasks/TASK-003-customer-web-surface.md`.

## Upstream Traceability
- Constitution: `../00_constitution/CONSTITUTION.md`
- Vision: `../01_vision/VISION.md`
- Business case: `../02_business_case/BUSINESS_CASE.md`
- Feature: `../10_features/FEAT-004-customer-web-surface.md`
- Goal impact: `../22_goal_impact/GOAL-IMPACT-TASK-003.md`

## Goal Impact
Improves customer conversion and onboarding while keeping MinIO storage private and operationally controlled.

## Project Invariants
- Preserve S3 root path and SigV4 behavior by serving the UI on a separate web deployment/host.
- Do not expose credentials, raw tokens, object inventories, or private URLs.
- Keep privileged admin details behind Auth role validation.

## Sensitive-Data Handling
Only synthetic metrics and examples are committed. Browser storage contains user session tokens only after Auth redirects; tokens are not logged or rendered.

## Contract Validation Plan
Use existing Leads submit and Auth login/register/validate contracts. The implementation does not change MinIO S3 contracts.

## Replay/Determinism Plan
Static rendering and local application drafts are deterministic. External Leads/Auth calls are integration-dependent.

## Scope
Create a static web app and Kubernetes manifests for a separate `storage.alfares.cz` web host. The current MinIO S3 service remains unchanged.

## Non-Goals
- No backend wrapper in this task.
- No browser-side MinIO credential issuance.
- No real object inventory listing.

## Files to Inspect
- `README.md`
- `nginx/nginx-api-routes.conf`
- `k8s/ingress.yaml`
- `17_governance/PROJECT_INVARIANTS.md`

## Files to Create
- `web/index.html`
- `web/styles.css`
- `web/app.js`
- `k8s/web/deployment.yaml`
- `k8s/web/service.yaml`
- `k8s/web/ingress.yaml`
- `k8s/web/configmap.yaml`
- `10_features/FEAT-004-customer-web-surface.md`
- `11_tasks/TASK-003-customer-web-surface.md`
- `12_validation/VAL-TASK-003-customer-web-surface.md`

## Files to Modify
- `README.md`
- `scripts/deploy.sh`
- `graph/project_graph.yaml`

## Files That Must Not Be Modified
- `00_constitution/CONSTITUTION.md`
- `01_vision/VISION.md`
- MinIO S3 root ingress semantics for `minio.alfares.cz`.

## Implementation Steps
1. Add static UI with landing, registration, client, and admin sections.
2. Wire Leads payload to the Leads submit endpoint.
3. Wire Auth login/register redirects and Auth validation role gating.
4. Add independent nginx static web deployment manifests.
5. Update deployment script to apply web manifests without changing MinIO service behavior.
6. Validate syntax and render with a temporary static server.

## Parallel Execution

Status: retrospective; TASK-003 is complete. Future customer web surface changes should use these independent workstreams and a final integration pass.

| Workstream | State | Owner role | Objective | Scope | Allowed files | Forbidden files | Dependencies | Validation evidence | Handoff notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TASK-003-A Static UI | ready now | Frontend engineer | Improve browser-safe landing, client, and admin shell without changing API contracts. | `web/` HTML/CSS/JS only. | `web/index.html`, `web/styles.css`, `web/app.js` | `k8s/`, `scripts/deploy.sh`, `.env*`, MinIO S3 ingress root behavior. | None for UI-only changes. | `node --check web/app.js`; desktop/mobile render evidence. | Keep examples synthetic and no object inventory. |
| TASK-003-B Platform manifests | ready now | Platform engineer | Maintain separate static web deployment/host for `storage.alfares.cz`. | Kubernetes web manifests only. | `k8s/web/deployment.yaml`, `k8s/web/service.yaml`, `k8s/web/ingress.yaml`, `k8s/web/configmap.yaml` | S3 host root ingress semantics for `minio.alfares.cz`, `.env*`, browser UI copy. | None unless UI asset paths change. | Manifest dry-run or deployment-readiness gate evidence. | Preserve separate host; no S3 root replacement. |
| TASK-003-C Auth and Leads contract review | ready now | Integration reviewer | Verify static UI uses Leads/Auth handoffs safely. | Contract review and small JS endpoint corrections only. | `web/app.js`, `13_context_packages/`, `14_prompts/`, `12_validation/` | Credentials, raw tokens in logs, backend wrapper changes. | None. | Syntax check plus contract evidence; no secrets. | Admin data must remain hidden unless Auth validates accepted admin role. |
| TASK-003-D Documentation and validation | ready now | Validation/documentation engineer | Keep README, graph, validation reports, and screenshots aligned with implementation. | Documentation and evidence files. | `README.md`, `graph/project_graph.yaml`, `12_validation/`, `reports/validation/` | Runtime behavior files unless fixing documented mismatch. | A-C outputs for final evidence. | `python3 scripts/pre_coding_gate.py --root .`; `python3 scripts/deployment_readiness_gate.py --root .` | Do not mark evidence complete until browser render and sensitive-data checks are present. |
| TASK-003-E Integration | final integration | minio-service-owner | Resolve conflicts, verify public contracts, and perform final release decision. | Final merge and deployment-readiness review. | Files changed by A-D. | Unrelated service files and secrets. | A-D complete. | All gates and render checks pass. | Merge order: UI, manifests, contract corrections, docs/evidence, final checklist. |

Shared files/contracts: `web/app.js` Auth/Leads endpoints, `storage.alfares.cz` web host, `minio.alfares.cz` S3 root behavior. Integration owner: `minio-service-owner`. Validation owner: TASK-003-D. Merge order: A -> B -> C -> D -> E, with C reviewing any A changes to Auth/Leads calls before final integration.

## Test Plan
- Static HTML/CSS/JS existence checks.
- Browser render at desktop and mobile viewport.
- Verify no credential-like secrets are committed in web files.
- Confirm admin data remains hidden without a valid administrator token.

## Validation Plan
- Run `node --check web/app.js`.
- Run `python3 scripts/pre_coding_gate.py --root .`.
- Run `python3 scripts/deployment_readiness_gate.py --root .` before production release.
- Render the static web UI at desktop and mobile viewport sizes.
- Confirm admin content is hidden without an accepted Auth administrator role.

## Gate Commands
```bash
python3 scripts/pre_coding_gate.py --root .
python3 scripts/deployment_readiness_gate.py --root .
```

## Documentation Updates
- README customer web surface section.
- Feature, task, goal-impact, execution-plan, prompt, validation report, and graph links.

## Rollback Plan
Remove `web/`, `k8s/web/`, TASK-003/FEAT-004/validation artifacts, graph entries, and the deploy script web manifest apply lines.

## Agent Handoff Prompt
Implement the customer web surface for MinIO as static browser-safe UI, preserve S3 endpoint root behavior, use Leads for intake, use Auth for registration/session validation, and never expose MinIO credentials or private object inventories in browser code.

## Completion Checklist
- [x] Implementation complete
- [x] Tests complete
- [x] Validation evidence collected
- [x] Documentation updated
- [x] Deviations documented
