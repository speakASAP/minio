# CLAUDE.md (minio-microservice)

→ Ecosystem: [../shared/CLAUDE.md](../shared/CLAUDE.md) | Reading order: `BUSINESS.md` → `SYSTEM.md` → `AGENTS.md` → `TASKS.md` → `STATE.json`

---

## minio-microservice

**Purpose**: S3-compatible object storage for lesson recordings and file artifacts. Private bucket with presigned URL access — no anonymous reads.  
**API port**: 9000 · **Console port**: 9001  
**Domain**: https://minio.alfares.cz  
**Stack**: MinIO · Kubernetes (`statex-apps`)

### Key constraints
- All objects are private — access only via presigned URLs, never public
- Bucket `records` layout must follow: `YYYY/MM/DD/lesson_<uuid>.mp3`
- Never expose storage credentials (ACCESS_KEY / SECRET_KEY)
- No anonymous read access — enforce bucket policies

### Consumers
speakasap-portal (lesson recordings), business-orchestrator (task artifacts).

**Ops**: `kubectl logs -n statex-apps -l app=minio-microservice -f` · `kubectl rollout restart deployment/minio-microservice -n statex-apps` · `./scripts/deploy.sh`
