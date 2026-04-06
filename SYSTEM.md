# System: minio-microservice

## Architecture

MinIO S3-compatible storage. Docker on Alfares server.

- API: port 9000/9002, Console: port 9001/9003
- Bucket `records`: key layout `YYYY/MM/DD/lesson_<uuid>.mp3`
- Access: presigned GET URLs only (no anonymous read)

## Integrations

| Consumer | Usage |
|---------|-------|
| speakasap-portal | Store + serve lesson MP3 recordings |
| business-orchestrator | Task artifact storage |

## Current State
<!-- AI-maintained -->
Stage: production

## Known Issues
<!-- AI-maintained -->
- None
