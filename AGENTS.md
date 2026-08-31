# Repository Agent Instructions

Shared rules live here:

- Codex profile: `/home/ssf/.codex/AGENTS.md`
- Cross-agent standard: `/home/ssf/.ai-agent-standards/CROSS_AGENT_AUTOMATION_STANDARD.md`
- Repository operations: `AGENT_OPERATIONS.md`

Read those first, then follow the repository-specific notes below and the current planning/status files.


## Repository-Specific Notes

# Agents: minio-microservice

## Knowledge Retrieval

Use `docs-rag-microservice` for bounded discovery when it is healthy, then
verify deployment, security, database, integration and public-contract facts
against the cited Git source. Git remains authoritative.

Authority and fallback rules:
`/home/ssf/Documents/Github/shared/docs/DOCUMENTATION_AUTHORITY.md`.

Do not generate tokens in documentation or assume an unconfident/failed RAG
response means that source documentation does not exist.

## Active Agents
<!-- Coordinator-maintained -->
None.\n\n---\n\n# AGENTS.md: minio-microservice
## Required Reading
Read BUSINESS.md, SYSTEM.md, constitution, vision, invariants, TASKS.md, and STATE.json before work.
## Authority
Owner-approved protected intent is authoritative; central adoption standard is in intent-preservation-system.
## Intent Preservation System
Trace vision through goal impact, system, task, plan, implementation, and validation.
## Safety and Operations
Never expose credentials, tokens, headers, raw objects, or full production presigned URLs. Preserve private buckets and SigV4 behavior.
## Project-Specific Rules
Preserve `records` privacy and `YYYY/MM/DD/lesson_<uuid>.mp3`; do not introduce anonymous reads.
## Required Final Report
Report role, files, validation, debt, blockers, deviations, and next action.
