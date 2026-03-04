# MinIO Records Storage – Integration

## Bucket and key layout

* **Bucket**: `records`
* **Key format**: `YYYY/MM/DD/lesson_<lesson_uuid>.mp3`
* **Example**: `2026/03/04/lesson_05e290d8-87b0-48d8-860c-cb6ace4e5d51.mp3`

Parts (before merge) can use: `YYYY/MM/DD/parts_<part_uuid>.mp3`.

## Producer (speakasap-portal, prod)

1. **Upload (lesson completion)**
   * Compute key from lesson date and UUID.
   * PUT object to bucket `records`, key as above.
   * No local disk storage; stream upload via S3 SDK.

2. **Merge task (multiple parts)**
   * Download part objects from S3 to temp files (or stream).
   * Merge to one MP3 (existing merge logic).
   * PUT merged file to S3 with key `YYYY/MM/DD/lesson_<lesson_uuid>.mp3`.
   * Update DB with key; delete temp files.

## Consumer (playback)

1. **Student requests playback**
   * Backend validates authorization (lesson belongs to student).
   * Generate presigned GET URL for the object (expiration e.g. 24 hours).
   * Return presigned URL to client (redirect or JSON).
   * Client downloads directly from MinIO (via dev Nginx); prod does not proxy or stream file.

## S3 API (MinIO-compatible)

* **Endpoint**: HTTPS URL to dev MinIO (e.g. `https://<dev-host>/minio/` or custom subdomain).
* **PUT** for uploads.
* **GetPresignedUrl** (or equivalent) for playback; no anonymous GET.
* Bucket has no public read; all access via presigned URLs or IAM.

## Environment (prod portal)

* `RECORDS_S3_ENDPOINT_URL` – MinIO API URL (HTTPS).
* `RECORDS_S3_BUCKET` – `records`.
* `RECORDS_S3_ACCESS_KEY` / `RECORDS_S3_SECRET_KEY` – credentials with read/write to bucket.
* `RECORDS_PRESIGNED_EXPIRY_SECONDS` – e.g. 86400 (24h).
