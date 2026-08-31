# System: minio-microservice

## Architecture

MinIO S3-compatible storage. Kubernetes (`statex-apps` namespace).

- API: port 9000, Console: port 9001
- Bucket `records`: key layout `YYYY/MM/DD/lesson_<uuid>.mp3`
- Access: presigned GET URLs only (no anonymous read)

## Deployment

**Platform:** Kubernetes (k3s) · namespace `statex-apps`  
**Image:** `localhost:5000/minio-microservice:latest`  
**Deploy:** `./scripts/deploy.sh`  
**Logs:** `kubectl logs -n statex-apps -l app=minio-microservice -f`  
**Restart:** `kubectl rollout restart deployment/minio-microservice -n statex-apps`

## Integrations

| Consumer | Usage |
|---------|-------|
| speakasap-portal | Store + serve lesson MP3 recordings |
| runlayer | Task artifact storage |

## Secrets

All secrets in Vault at `secret/prod/minio-microservice`.  
Synced via ESO → K8s Secret `minio-microservice-secret`.

## Current State
<!-- AI-maintained -->
Stage: production · Deploy: Kubernetes (`statex-apps`)

## Known Issues
<!-- AI-maintained -->
- None\n\n---\n\n# System: minio-microservice
```yaml
id: SYSTEM-minio-microservice
status: validated
owner: project owner
created: 2026-06-13
last_updated: 2026-08-30
completeness_level: validated
upstream: [BUSINESS.md, docs/01_vision/VISION.md]
downstream: [docs/06_architecture/INTEGRATION_CONTRACT.md, docs/17_governance/PROJECT_INVARIANTS.md]
```
## Purpose
Operate private S3-compatible MinIO storage in Kubernetes namespace `statex-apps`.
## Responsibilities
Expose MinIO S3 on 9000 and console on 9001, retain private objects, and deploy a read-only authenticated metadata wrapper.
## Non-Responsibilities
This service owns neither consumer workflows, relational data, Redis data, nor RabbitMQ events.
## Inputs
Authenticated S3 operations, presigned GET requests, Vault-synced configuration, and admin bearer tokens.
## Outputs
Private S3 objects, presigned access, health endpoints, and safe admin metadata.
## Dependencies
MinIO runs from `minio/minio`; ESO supplies Vault configuration. The wrapper validates through auth-microservice and logs to logging-microservice.
## Upstream Traceability
BUSINESS.md, the constitution, and vision define privacy, key-layout, and credential constraints.
## Downstream Artifacts
The integration contract, invariants, and bootstrap delivery chain operationalize this contract.
## Validation Criteria
MinIO probes call `/minio/health/live`, admin API probes call `/healthz`, and SigV4-sensitive changes require safe S3 validation.
## Open Questions
The documented records key layout and wrapper default bucket name require alignment before configuration or consumer changes; this task makes none.
