# Prompt Guidelines

```yaml
id: PROMPT-GUIDELINES
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../17_governance/AI_AGENT_RULES.md
downstream:
  - ./PROMPT-TASK-001-ips-documentation-bootstrap.md
related_adrs:
  - ADR-001
```

## Prompt principles
Use the smallest context package, preserve MinIO invariants, require validation, and use synthetic examples only.

## Prompt structure
Task summary, execution plan link, context, allowed changes, forbidden changes, implementation instructions, acceptance criteria, validation commands, and expected output.

## Anti-patterns
Pasting credentials, real presigned URLs, raw production data, vague tasks, or proxy changes without SigV4 validation.
