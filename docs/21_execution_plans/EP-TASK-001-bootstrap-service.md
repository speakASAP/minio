# EP-TASK-001-bootstrap-service: Canonical IPS adoption
```yaml
id: EP-TASK-001-bootstrap-service
status: closed
owner: project owner
created: 2026-08-30
last_updated: 2026-08-30
completeness_level: validated
```
## Upstream Traceability
../11_tasks/TASK-001-bootstrap-service.md, ../22_goal_impact/GOAL-IMPACT-TASK-001.md, ../12_validation/VAL-TASK-001-bootstrap-service.md, ../../BUSINESS.md, and ../../SYSTEM.md.
## Scope
Complete canonical adoption documents and integration review for the existing service.
## Non-Goals
No runtime, deployment, secret, schema, bucket, CORS, or proxy change.
## Project Invariants
Apply ../17_governance/PROJECT_INVARIANTS.md.
## Sensitive-Data Handling
Use only sanitized facts; exclude credentials, headers, raw objects, and full production URLs.
## Contract Validation Plan
Verify claims against wrapper code, Kubernetes configuration, and consumer documentation.
## Replay and Determinism Plan
No runtime replay change; adoption validation is deterministic.
## Files to Inspect
Root contracts, backend/wrapper_api.py, k8s, existing docs, and central validator.
## Files to Create
Canonical profile and missing canonical task-chain files.
## Files to Modify
Canonical contracts, state, governance, intent, task-chain, and debt documents.
## Files That Must Not Be Modified
Runtime manifests, Vault secrets, bucket contents, or consumer repositories.
## Implementation Steps
Inspect, scaffold, reconcile existing evidence, complete review, validate.
## Parallel Execution
Documentation reconciliation is completed by the integration owner; final validation is final integration by the validation owner. Shared files are ips-adoption.json and STATE.json; validation merges last.
## Blockers
No blocker prevents adoption; MinIO bucket backups are a future extension.
## Test Plan
Run the planning validator; runtime tests are outside this documentation-only scope.
## Validation Plan
Record validator success and preserved invariants in the validation report.
## Gate Commands
`python3 intent-preservation-system/scripts/validate_adoption_profile.py --root minio-microservice --phase planning`
## Documentation Updates
Canonical files coexist with the older numbered IPS documentation tree.
## Rollback Plan
Revert this documentation commit if a statement is inaccurate; no runtime rollback is required.
## Handoff
Provide validator output, commit, changed files, debt, and blockers.
## Completion Checklist
Protected intent approved; decisions complete; planning profile valid; evidence recorded.
