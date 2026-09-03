# EP-TASK-002: Review Presigned URL TTL Settings

```yaml
id: EP-TASK-002
status: done
source_task: ../11_tasks/TASK-002-review-presigned-url-ttl-settings.md
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-09-03
completeness_level: complete
vision: ../01_vision/VISION.md
constitution: ../00_constitution/CONSTITUTION.md
feature: ../10_features/FEAT-002-presigned-access-boundary.md
goal_impact: ../22_goal_impact/GOAL-IMPACT-TASK-002.md
```

## Metadata
Task TASK-002; complete. External TTL values were verified on 2026-09-03 and the remaining markers are resolved below.

## Upstream Traceability
Vision, relevant feature/milestone, task, ADR where applicable, and goal impact record.

## Goal Impact
Preserves private MinIO storage intent and operational safety.

## Project Invariants
Must preserve bucket privacy, credential secrecy, key layout, SigV4 correctness, and validation evidence.

## Sensitive-Data Handling
Use only non-secret docs and synthetic examples. Do not include .env values, credentials, authorization headers, raw production object data, or full presigned production URLs.

## Contract Validation Plan
TASK-002 made no MinIO-side runtime, endpoint, nginx, bucket policy, or consumer contract change. Any future TTL or endpoint behavior change must be validated with documentation updates and S3 signature checks.

## Replay/Determinism Plan
No runtime replay effect unless a future config change is made; gates should be repeatable.

## Scope
Review TTL expectations and update docs/config only if explicitly required.

## Non-Goals
Runtime behavior changes outside scope, deployment changes without validation, and human approval claims.

## Files to Inspect
BUSINESS.md, SYSTEM.md, README.md, TASKS.md, STATE.json, AGENTS.md, scripts, nginx, and relevant k8s manifests.

## Files to Create
IPS documents, validation reports, context packages, prompts, graph files, and reports as applicable.

## Files to Modify
Only files named in the task scope.

## Files That Must Not Be Modified
.env, .env.backup*, secret-bearing files, unrelated dirty k8s/deployment.yaml work, and consumer repos without separate approval.

## Implementation Steps
1. Read required docs.
2. Confirm traceability and invariants.
3. Make scoped documentation or configuration changes.
4. Run gates and relevant service checks.
5. Record validation evidence.

## Parallel Execution

Status: integrated. TASK-002-A, TASK-002-B, and TASK-002-C completed; TASK-002-D integrated MinIO-side findings with external TTL-value verification still pending.

| Workstream | State | Owner role | Objective | Scope | Allowed files | Forbidden files | Dependencies | Validation evidence | Handoff notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TASK-002-A TTL source discovery | completed | Storage integration engineer | Locate the effective presigned URL TTL in MinIO, portal integration docs, scripts, and nginx assumptions. | Read-only discovery plus a short evidence note. | `README.md`, `docs/`, `scripts/`, `nginx/`, `k8s/`, `docs/23_documentation_contracts/`, `reports/validation/` | `.env*`, secret-bearing files, consumer repos unless separately approved. | None. | Commands used for discovery; no secrets in output. | Mark absent facts using the MISSING marker convention; do not infer production values from examples. |
| TASK-002-B Policy and invariant review | completed | Security documentation reviewer | Compare discovered TTL expectations against privacy, presigned-access, and sensitive-data invariants. | Documentation-only review. | `docs/17_governance/PROJECT_INVARIANTS.md`, `docs/10_features/FEAT-002-presigned-access-boundary.md`, `docs/22_goal_impact/GOAL-IMPACT-TASK-002.md`, `docs/11_tasks/TASK-002-review-presigned-url-ttl-settings.md` | Runtime code, deployment scripts, `.env*`. | None. | Written finding list with invariant IDs and MISSING markers where needed. | Do not change TTL behavior; recommend only. |
| TASK-002-C Validation readiness | completed | Validation engineer | Define and run safe checks that prove docs and gates are ready before any release-impacting change. | Gate execution and validation report preparation. | `docs/12_validation/`, `reports/validation/`, `scripts/` for read-only command execution | Secrets, runtime configs, unrelated dirty files. | None. | `python3 scripts/pre_coding_gate.py --root .`; `python3 scripts/deployment_readiness_gate.py --root docs --target TASK-002`; S3 signature test only if runtime behavior changes. | If a command requires credentials, stop and record a MISSING marker for safe credentials/approval. |
| TASK-002-D Integration and decision | completed for MinIO-side docs | minio-service-owner | Combine A-C findings, decide whether docs only or scoped config work is needed, update task/prompt/validation truthfully. | Final documentation edits and status update. | `docs/21_execution_plans/EP-TASK-002-review-presigned-url-ttl-settings.md`, `docs/11_tasks/TASK-002-review-presigned-url-ttl-settings.md`, `docs/12_validation/`, `docs/14_prompts/` if a coding prompt is needed, `graph/project_graph.yaml` if new artifacts are added | `.env*`, MinIO credentials, consumer repos without approval. | A-C complete. | All applicable gates pass and evidence is linked. | Merge order: A discovery, B policy findings, C validation evidence, D final docs. |

Shared files/contracts: presigned URL TTL policy, S3 endpoint root semantics, sensitive-data policy, IPS graph links. Integration owner: `minio-service-owner`. Validation owner: TASK-002-C. Merge order: A -> B -> C -> D. No parallel agent may change shared public contracts or runtime TTL without integration-owner approval.

## Integrated Decision
No MinIO-side runtime/configuration change is required from the available evidence. The documented policy remains: presigned URL expiration must be `<= 24 hours`, with `15-60 minutes` preferred for normal playback when consumer regeneration is available.

## Resolved External Facts (2026-09-03)
- Effective production presigned TTL: **900 seconds (15 minutes)**. `portal/local_settings_default.py`
  and `portal/settings.py` both resolve `RECORDS_PRESIGNED_EXPIRY_SECONDS` to `900` when unset, and the
  production portal configuration sets the same value, so the effective TTL is 900 either way. This sits
  inside the documented cap of `<= 24 hours` and within the preferred `15-60 minutes` band, so the
  MinIO-side decision of "no change required" is now evidence-backed rather than assumed.
- Runlayer presigned URL TTL: **not applicable - runlayer does not generate presigned URLs.** It has no
  S3/MinIO client and no `aws-sdk`, `boto3` or `minio` dependency; the only superficially related matches
  are an unrelated JWT `expiresIn` in `.env.example` and a display-only expiry string in `public/app.js`.
- SigV4 validation credentials: **not required for this task.** The Test Plan scopes S3 signature tests to
  "when runtime access behavior changes", and no runtime or configuration change was made. The only MinIO
  credential held in the cluster is the root credential, which this plan's invariants forbid using. If a
  future task changes runtime access behavior, it must first obtain a scoped non-root credential.

Validation report: `../12_validation/VAL-TASK-002-review-presigned-url-ttl-settings.md`.

## Test Plan
Run strict documentation audit and pre-coding gate; run S3 signature tests when runtime access behavior changes.

## Validation Plan
Record command results and safe evidence in the matching validation report.

## Gate Commands
```bash
python3 scripts/strict_doc_audit.py --format markdown --fail-on-issues
python3 scripts/pre_coding_gate.py --root .
python3 scripts/deployment_readiness_gate.py --root . --target TASK-002
```

## Documentation Updates
Update IPS docs and root docs only when required by the scoped task.

## Rollback Plan
Revert scoped documentation/configuration changes and rerun gates.

## Agent Handoff Prompt
Complete only the scoped task, preserve MinIO privacy invariants, avoid secrets, and record validation evidence.

## Completion Checklist
- [x] Implementation complete for MinIO-side documentation review
- [x] Tests complete for safe documentation gates
- [x] Validation evidence collected
- [x] Documentation updated
- [x] Deviations documented
