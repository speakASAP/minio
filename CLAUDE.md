# Claude Instructions

Shared rules live here:

- Claude profile: `/home/ssf/.claude/CLAUDE.md`
- Shared ecosystem instructions: `/home/ssf/Documents/Github/CLAUDE.md`
- Codex profile: `/home/ssf/.codex/AGENTS.md`
- Cross-agent standard: `/home/ssf/.ai-agent-standards/CROSS_AGENT_AUTOMATION_STANDARD.md`
- Repository operations: `AGENT_OPERATIONS.md`

Read those first, then follow the repository-specific notes below and the current planning/status files.


## Repository-Specific Notes

# CLAUDE.md (minio-microservice)

→ Ecosystem: [../shared/CLAUDE.md](../shared/CLAUDE.md) | Reading order: `BUSINESS.md` → `SYSTEM.md` → `AGENTS.md` → `TASKS.md` → `STATE.json`

---

## Knowledge Retrieval — docs-rag-microservice (MANDATORY, query before reading files)

**Query the RAG before reading source files** — saves 2000-5000 tokens per answer.

```bash
kubectl -n statex-apps exec deployment/minio-microservice -- curl -s -X POST http://docs-rag-microservice:3397/retrieval/agent-context \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat ~/.claude/rag-token)" \
  -d '{"query": "YOUR QUESTION HERE", "maxTokens": 3000}'
```

---

## minio-microservice

**Purpose**: S3-compatible object storage for lesson recordings and file artifacts. Private bucket with presigned URL access — no anonymous reads.  

**Domain**: <https://minio.alfares.cz>z>  
**Stack**: MinIO · Docker

### Key constraints

- All objects are private — access only via presigned URLs, never public
- Bucket `records` layout must follow: `YYYY/MM/DD/lesson_<uuid>.mp3`
- Never expose storage credentials (ACCESS_KEY / SECRET_KEY)
- No anonymous read access — enforce bucket policies

### Consumers

speakasap-portal (lesson recordings), runlayer (task artifacts).

docker compose logs -f

./scripts/deploy.sh
