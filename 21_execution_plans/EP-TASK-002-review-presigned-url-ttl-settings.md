# EP-TASK-002: Review Presigned URL TTL Settings

```yaml
id: EP-TASK-002
status: draft
source_task: ../11_tasks/TASK-002-review-presigned-url-ttl-settings.md
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
vision: ../01_vision/VISION.md
constitution: ../00_constitution/CONSTITUTION.md
feature: ../10_features/FEAT-002-presigned-access-boundary.md
goal_impact: ../22_goal_impact/GOAL-IMPACT-TASK-002.md
```

## Metadata
Task TASK-002; lifecycle state draft.

## Upstream Traceability
Vision, relevant feature/milestone, task, ADR where applicable, and goal impact record.

## Goal Impact
Preserves private MinIO storage intent and operational safety.

## Project Invariants
Must preserve bucket privacy, credential secrecy, key layout, SigV4 correctness, and validation evidence.

## Sensitive-Data Handling
Use only non-secret docs and synthetic examples. Do not include .env values, credentials, authorization headers, raw production object data, or full presigned production URLs.

## Contract Validation Plan
Documentation-only for TASK-001. For TASK-002, validate any TTL or endpoint behavior change with docs and S3 signature checks.

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
- [ ] Implementation complete
- [ ] Tests complete
- [ ] Validation evidence collected
- [ ] Documentation updated
- [ ] Deviations documented
