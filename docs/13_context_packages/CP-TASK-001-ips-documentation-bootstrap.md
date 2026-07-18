# Context Package: TASK-001

```yaml
id: CP-TASK-001
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../11_tasks/TASK-001-ips-documentation-bootstrap.md
downstream:
  - ../14_prompts/PROMPT-TASK-001-ips-documentation-bootstrap.md
related_adrs:
  - ADR-001
```

## Target task
`../11_tasks/TASK-001-ips-documentation-bootstrap.md`

## Upstream traceability

- `../01_vision/VISION.md`
- `../02_business_case/BUSINESS_CASE.md`
- `../07_decisions/ADR-001-adopt-intent-preservation-system.md`

## Included documents
BUSINESS.md, SYSTEM.md, README.md, TASKS.md, STATE.json, and company IPS documentation contracts/templates.

## Excluded documents
.env, .env.backup*, secret-bearing runtime files, and raw production object data.

## Constraints
Do not change runtime behavior, deployment configuration, or secret files.

## Agent prompt
Create MinIO IPS documentation from root docs and company standard templates while preserving private storage and credential secrecy.

## Validation instructions
Run IPS gates and record safe evidence.
