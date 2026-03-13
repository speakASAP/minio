# MinIO Records Storage – Integration

## Bucket and key layout

* **Bucket**: `speakasap-records` (configurable via `RECORDS_S3_BUCKET`).
* **Key format**: `YYYY/MM/DD/lesson_<lesson_uuid>.mp3` (no trailing slash; keys are normalized so MinIO stores objects as files, not directory placeholders).
* **Example**: `2026/03/04/lesson_05e290d8-87b0-48d8-860c-cb6ace4e5d51.mp3`

Parts (before merge) use: `YYYY/MM/DD/parts_<part_uuid>.<ext>`.

## Producer (speakasap-portal, prod)

1. **Upload (lesson completion)**
   * Compute key from lesson date and UUID.
   * PUT object to bucket `speakasap-records`, key as above (via local S3 helper or storage).
   * No local disk storage; upload via S3 SDK (helper or RecordsS3Storage).

2. **Merge task (multiple parts)**
   * Download part objects from S3 to temp files (or stream).
   * Merge to one MP3 (existing merge logic).
   * PUT merged file to S3 with key `YYYY/MM/DD/lesson_<lesson_uuid>.mp3`.
   * Update DB with key (trailing slash stripped); delete temp files.

## Consumer (playback)

1. **Teacher / manager / student playback**
   * Backend validates authorization.
   * Generate presigned GET URL for the object (expiration e.g. 900–86400 seconds).
   * Return redirect to presigned URL (teacher/manager) or URL in JSON.
   * Client (browser) loads audio directly from MinIO at `https://minio.alfares.cz/...`. MinIO nginx proxy adds CORS headers so the portal origin can use the response. The client must be able to reach `minio.alfares.cz` (firewall/DNS).

## S3 API (MinIO-compatible)

* **Endpoint**: Root HTTPS URL only (e.g. `https://minio.alfares.cz`). Do not use a path prefix such as `/minio/` — the portal must sign path-style requests so the path matches what MinIO receives (root `/` location proxies full URI).
* **PUT** for uploads (path-style: `/bucket/key`).
* **GetPresignedUrl** (or equivalent) for playback; no anonymous GET.
* Bucket has no public read; all access via presigned URLs or IAM.

## Environment (prod portal)

* `RECORDS_S3_ENDPOINT_URL` – MinIO API root URL (HTTPS, no trailing path, e.g. `https://minio.alfares.cz`).
* `RECORDS_S3_BUCKET` – `speakasap-records`.
* `RECORDS_S3_ACCESS_KEY` / `RECORDS_S3_SECRET_KEY` – credentials with read/write to bucket.
* `RECORDS_PRESIGNED_EXPIRY_SECONDS` – e.g. 900 (15 min) or 86400 (24h).
