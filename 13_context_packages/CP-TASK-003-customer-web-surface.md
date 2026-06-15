# CP-TASK-003: Customer Web Surface Context Package

```yaml
id: CP-TASK-003
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
source_task: ../11_tasks/TASK-003-customer-web-surface.md
```

## Target task
TASK-003: `../11_tasks/TASK-003-customer-web-surface.md`

## Upstream traceability
- Constitution: `../00_constitution/CONSTITUTION.md`
- Vision: `../01_vision/VISION.md`
- Business case: `../02_business_case/BUSINESS_CASE.md`
- System: `../04_systems/SYS-001-private-object-storage.md`
- Feature: `../10_features/FEAT-004-customer-web-surface.md`
- Goal impact: `../22_goal_impact/GOAL-IMPACT-TASK-003.md`
- Execution plan: `../21_execution_plans/EP-TASK-003-customer-web-surface.md`

## Included documents
- `../README.md`
- `../17_governance/PROJECT_INVARIANTS.md`
- `../23_documentation_contracts/SENSITIVE_DATA_POLICY.md`
- `../10_features/FEAT-004-customer-web-surface.md`
- `../11_tasks/TASK-003-customer-web-surface.md`
- `../21_execution_plans/EP-TASK-003-customer-web-surface.md`
- `../22_goal_impact/GOAL-IMPACT-TASK-003.md`
- `../14_prompts/PROMPT-TASK-003-customer-web-surface.md`

## Excluded documents
- MinIO root credential files.
- Production object inventories.
- Raw access tokens, private keys, customer secrets, or private presigned URLs.
- Immutable vision and constitution edits.

## Constraints
- Preserve `minio.alfares.cz` as the S3 path-style endpoint.
- Serve the web surface separately from the S3 API root.
- Route prospect intake through Leads and identity through Auth.
- Do not expose credentials, private object inventory, or privileged mutations in static browser code.

## Agent prompt
Implement and validate the customer web surface for TASK-003 using the execution plan. Keep the browser implementation static and credential-free, use Leads for intake, use Auth for registration and administrator role validation, and document any backend-only capabilities as deferred.

## Validation instructions
- Run `node --check web/app.js`.
- Run `python3 scripts/pre_coding_gate.py --root .`.
- Run `python3 scripts/deployment_readiness_gate.py --root .` before release.
- Inspect desktop and mobile rendering.
- Confirm no committed secrets or private object inventories exist in the web surface.
