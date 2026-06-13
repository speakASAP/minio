# Core Entities

```yaml
id: CORE-ENTITIES
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ./GLOSSARY.md
  - ../01_vision/VISION.md
downstream:
  - ../04_systems/SYS-001-private-object-storage.md
related_adrs:
  - ADR-001
```

## Entity Relationship Overview
Consumer -> S3 request -> MinIO endpoint -> private bucket -> object key -> stored object. Consumer -> presigned GET URL -> Nginx proxy -> MinIO -> private object.

## Consumer
Trusted service that owns upload or playback workflow and receives credentials through environment or secret management.

## S3 Endpoint
URL used by consumers for S3 API operations. Public production traffic uses https://minio.alfares.cz.

## Bucket
Private object namespace for recordings and artifacts. Public anonymous policy is forbidden.

## Object
Stored file data, primarily lesson MP3 recordings and task artifacts.

## Key Layout
The lesson recording path convention: YYYY/MM/DD/lesson_<uuid>.mp3.

## Credential Set
MinIO access key and secret key values. These are sensitive and must never be committed or quoted in IPS artifacts.

## Diagnostic Evidence
Health, proxy, signature, and log summaries that prove operational state without exposing secrets or raw production data.
