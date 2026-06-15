# Agents: minio-microservice


## Knowledge Retrieval (query before reading files)
Query the RAG service first to reuse indexed ecosystem context before reading raw files:

```bash
curl -s -X POST http://docs-rag-microservice.statex-apps.svc.cluster.local:3397/retrieval/agent-context \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "YOUR QUESTION HERE", "maxTokens": 3000}'
```

- Internal URL: `http://docs-rag-microservice.statex-apps.svc.cluster.local:3397`
- Public URL: `https://docs-rag.alfares.cz`
- Full guide: `docs-rag-microservice/docs/RAG_USAGE.md`

N/A — infrastructure service. No AI agent coordination.

## Active Agents
<!-- Coordinator-maintained -->
None.

## Company Cross-Agent Standard

This repository also follows `AGENT_OPERATIONS.md`, which points all AI agents to the company cross-agent automation model: readiness scanner, bounded worker agent, worker monitor, and integration validator. Use the validation-debt ledger for known out-of-scope validation failures and preserve the Intent Preservation chain.

## Central Instruction Source

Shared agent rules now live in `/home/ssf/.codex/AGENTS.md` and `/home/ssf/.ai-agent-standards/CROSS_AGENT_AUTOMATION_STANDARD.md`. Keep this file for repository-specific constraints only; do not duplicate shared operating rules here.
