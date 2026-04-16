# CLAUDE.md (minio-microservice)

Ecosystem defaults: sibling [`../CLAUDE.md`](../CLAUDE.md) and [`../shared/docs/PROJECT_AGENT_DOCS_STANDARD.md`](../shared/docs/PROJECT_AGENT_DOCS_STANDARD.md).

Read this repo's `BUSINESS.md` → `SYSTEM.md` → `AGENTS.md` → `TASKS.md` → `STATE.json` first.

---

## minio-microservice

**Purpose**: S3-compatible object storage for lesson recordings and file artifacts. Private bucket with presigned URL access — no anonymous reads.  
**API ports**: 9000 (blue) · 9002 (green)  
**Console ports**: 9001 (blue) · 9003 (green)  
**Domain**: https://minio.alfares.cz  
**Stack**: MinIO · Docker

### Key constraints
- All objects are private — access only via presigned URLs, never public
- Bucket `records` layout must follow: `YYYY/MM/DD/lesson_<uuid>.mp3`
- Never expose storage credentials (ACCESS_KEY / SECRET_KEY)
- No anonymous read access — enforce bucket policies

### Consumers
speakasap-portal (lesson recordings), business-orchestrator (task artifacts).

### Quick ops
```bash
docker compose logs -f
./scripts/deploy.sh
```
