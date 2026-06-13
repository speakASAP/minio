# PROMPT-TASK-001: IPS Documentation Bootstrap

```yaml
id: PROMPT-TASK-001
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../21_execution_plans/EP-TASK-001-ips-documentation-bootstrap.md
downstream:
  - ../12_validation/VAL-TASK-001-ips-documentation-bootstrap.md
related_adrs:
  - ADR-001
```

## Role
Documentation bootstrap agent for minio-microservice.

## Task
Create the IPS documentation layer without runtime behavior changes.

## Context
Use root docs, company IPS templates, and RAG bootstrap reference.

## Constraints
Do not expose secrets, raw production data, authorization headers, or full presigned URLs.

## Task Summary
Create the IPS documentation layer for minio-microservice.

## Execution Plan Link
../21_execution_plans/EP-TASK-001-ips-documentation-bootstrap.md

## Required Context
Root docs and company IPS templates/contracts.

## Allowed Changes
Create documentation, templates, graph schema, gate scripts, and validation artifacts required for IPS bootstrap.

## Forbidden Changes
Do not modify .env, .env.backup*, unrelated dirty runtime files, deployment behavior, or secret-bearing files.

## Implementation Instructions
Preserve private S3 storage, presigned-only reads, stable key layout, SigV4 proxy correctness, and credential secrecy.

## Acceptance Criteria
IPS structure, required bootstrap docs, TTL task, gates, and validation evidence exist.

## Validation Commands
python3 scripts/strict_doc_audit.py --format markdown --fail-on-issues; python3 scripts/pre_coding_gate.py --root .

## Expected Output
Documentation-only bootstrap with no runtime behavior changes.

## Validation
Run strict documentation audit and pre-coding gate; record results without secrets.
