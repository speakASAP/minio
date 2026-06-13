# Agent Onboarding Package

```yaml
id: ONBOARDING-AGENT
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../00_constitution/CONSTITUTION.md
  - ../01_vision/VISION.md
  - ../17_governance/AI_AGENT_RULES.md
downstream: []
related_adrs:
  - ADR-001
```

## Project purpose
minio-microservice provides private S3-compatible object storage for lesson recordings and service artifacts.

## Immutable documents
Do not modify constitution or vision after bootstrap unless the owner explicitly asks through change control.

## Required workflow
Read root docs and IPS docs, confirm task and plan, run gates, make only scoped changes, and record validation evidence.

## Before starting work
Check git status, avoid unrelated dirty files, query docs RAG when available, and never copy secret values into outputs.

## Forbidden actions
Do not expose credentials, raw production objects, authorization headers, or full production presigned URLs. Do not make buckets public or alter proxy behavior without validation.

## Documentation gap handling
Fill gaps only from approved source docs. Otherwise keep draft status and document the gap.

## Expected final output
Report changed files, validation commands, gate evidence, remaining risks, and deviations.
