# AI Agent Rules

```yaml
id: AI-AGENT-RULES
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../00_constitution/CONSTITUTION.md
  - ../01_vision/VISION.md
downstream:
  - ../24_onboarding/ONBOARDING_AGENT.md
related_adrs:
  - ADR-001
```

## Purpose
Define how AI agents may work in minio-microservice after IPS adoption.

## Immutable documents
After bootstrap, AI agents must not modify 00_constitution/CONSTITUTION.md or 01_vision/VISION.md without owner instruction.

## Required work chain
Vision -> Goal Impact -> System -> Feature -> Task -> Execution Plan -> Prompt -> Code -> Validation.

## Before coding
Verify task, upstream traceability, goal impact, execution plan, context package, validation criteria, invariants, sensitive-data classification, contract impact, replay impact, and gates.

## Documentation gap behavior
Fill gaps only from approved upstream sources. Otherwise mark the gap in mutable docs.

## Forbidden behavior
Do not expose credentials, authorization headers, raw production object data, or full production presigned URLs. Do not make buckets public or alter proxy behavior without SigV4 validation.

## Required final report
Report changed files, documents created, gaps, validation evidence, and deviations.
