# Onboarding Generation Guide

```yaml
id: ONBOARDING-GUIDE
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../01_vision/VISION.md
downstream:
  - ./ONBOARDING_AGENT.md
related_adrs:
  - ADR-001
```

## Purpose
Generate concise onboarding from approved MinIO docs without loading the entire repository.

## Output files
Place generated onboarding under 24_onboarding/generated/ when needed.

## Human onboarding package
Include purpose, consumers, private-storage rules, deployment model, diagnostics, and documentation review.

## Agent onboarding package
Include immutable docs, workflow, forbidden actions, sensitive-data rules, execution-plan rules, and validation requirements.

## Generation inputs
Use constitution, vision, business case, architecture, ADRs, roadmap, documentation contracts, and project invariants.

## Refresh triggers
Refresh after vision evolution, major ADR, roadmap changes, gate changes, or deployment contract changes.

## Completeness checklist
Explains purpose, immutable docs, workflow, architecture links, validation, and forbidden actions.
