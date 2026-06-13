# Audit Checklist

```yaml
id: AUDIT-CHECKLIST
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../23_documentation_contracts/DOCUMENTATION_COMPLETENESS_STANDARD.md
downstream:
  - ./AUDIT-2026-06-13-ips-bootstrap.md
related_adrs:
  - ADR-001
```

## Core source-of-truth checks
Constitution, vision, business case, and invariants exist.

## Decomposition checks
System, subsystem, feature, task, and execution plan documents exist and link upstream.

## Goal impact checks
Tasks and execution plans link to goal impact records.

## Execution plan checks
Plans define scope, non-goals, files, validation, gates, rollback, and handoff.

## Security checks
No credentials, authorization headers, raw production objects, or full production presigned URLs appear in IPS artifacts.

## Validation checks
Completed tasks have validation reports and gate evidence.

## Audit output
Findings, risks, recommendations, and traceability confirmation.
