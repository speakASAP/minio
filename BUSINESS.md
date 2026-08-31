# Business: minio-microservice
>
> ⚠️ IMMUTABLE BY AI.

## Goal

S3-compatible object storage for lesson recordings and file artifacts. Private bucket with presigned URL access.

## Constraints

- Bucket `records` layout: `YYYY/MM/DD/lesson_<uuid>.mp3`
- No anonymous read — presigned URLs only
- AI must never expose storage credentials

## Consumers

speakasap-portal (lesson recordings), runlayer (task artifacts).

## SLA

- API port: 9000/9002
- Console port: 9001/9003
- Production: <https://minio.alfares.cz>\n\n---\n\n# Business: minio-microservice

```yaml
id: BUSINESS-minio-microservice
status: approved
owner: project owner
created: 2026-06-13
last_updated: 2026-08-30
completeness_level: complete
upstream: [docs/00_constitution/CONSTITUTION.md, docs/01_vision/VISION.md]
downstream: [SYSTEM.md, docs/22_goal_impact/GOAL-IMPACT-TASK-001.md]
```
## Problem
The ecosystem needs durable object storage for lesson recordings and task artifacts without NFS coupling.
## Target Users and Stakeholders
speakasap-portal stores lesson recordings, runlayer stores task artifacts, and operators maintain the storage boundary.
## Value Proposition
Private S3-compatible MinIO storage provides controlled presigned object access.
## Goals
Keep the records bucket private, preserve `YYYY/MM/DD/lesson_<uuid>.mp3`, and serve reads through authenticated S3 or presigned URLs.
## Non-Goals
Anonymous object hosting, exposing storage credentials, and consumer business workflows.
## Success Metrics
The API is available on ports 9000/9002, console on 9001/9003, and production endpoint is `https://minio.alfares.cz`.
## Business Constraints
No anonymous reads; credentials remain in Vault and External Secrets-managed configuration.
## Approval
Status: approved
Approved by: project owner
Approval evidence: owner-confirmation: minio-microservice-onboarding-approved
