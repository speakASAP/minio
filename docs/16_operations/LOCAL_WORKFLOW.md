# Local Workflow

```yaml
id: LOCAL-WORKFLOW
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../17_governance/AI_AGENT_RULES.md
downstream:
  - ../21_execution_plans/EP-TASK-001-ips-documentation-bootstrap.md
related_adrs:
  - ADR-001
```

## Daily project workflow
Read root docs, query docs RAG when available, confirm task/goal impact/plan/validation, run pre-coding gate, and record validation evidence.

## Git workflow
Do not overwrite unrelated dirty changes. Do not commit secrets, raw production objects, or full presigned production URLs.

## Commit message convention
Use clear service-scoped messages such as docs: add minio IPS bootstrap.
