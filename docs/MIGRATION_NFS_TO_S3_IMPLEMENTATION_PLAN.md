# AI Agent Implementation Plan

## Migration from NFS to S3-Compatible Object Storage (MinIO Microservice)

---

# OBJECTIVE

Replace current NFS-based shared storage with a dedicated S3-compatible object storage microservice (MinIO) running on dev server (85.163.140.109).

Requirements:

* Zero downtime during migration
* No filesystem mounts on prod
* Prod becomes fully stateless regarding records
* Storage handled via S3 API only
* MinIO integrated as a standard microservice following existing project README conventions

---

# CURRENT STATE

## Prod (speakasap)

Mounted path:
`/home/portal_db/speakasap-portal/materials/courses/records`

Current NFS:
`188.40.71.214:/srv/share/records`

Access: `ssh speakasap` → `cd speakasap-portal`

Ubuntu 16 – legacy system.

## Dev

Public IP: 85.163.140.109  
Current storage path for copied lesson records: `/srv/speakasap-records` (years/ months/ days/ `lesson_<uuid>.mp3`, ~2 TB copied from NFS).  
Access: `ssh dev`  
Nginx already installed. Dev is capable of hosting additional microservice.

---

# TARGET ARCHITECTURE

* MinIO runs as separate microservice on dev.
* Bucket: `RECORDS_BUCKET` (currently `speakasap-records`).
* Object key: `YYYY/MM/DD/lesson_UUID.mp3` (e.g. `2026/03/04/lesson_05e290d8-87b0-48d8-860c-cb6ace4e5d51.mp3`)
* Prod: PUT object + generate presigned GET URL only. No NFS, no shared filesystem.

---

# PHASE 1 — CREATE MINIO MICROSERVICE ON DEV

## 1. Follow microservice standards

* [x] Read README.md and CREATE_SERVICE.md
* [x] MinIO follows project structure: README, docs/, .env.example, scripts
* [x] Nginx reverse proxy style; SSL via existing cert process on dev
* [x] Service runs on dev (85.163.140.109), not statex prod

## 2. Deploy MinIO on dev

* [x] Create `/srv/minio-data` on dev; create system user `minio`, `chown -R minio:minio /srv/minio-data`
* [x] Systemd service: bind 127.0.0.1:9000, `minio server /srv/minio-data --console-address ":9001"`
* [x] Point MinIO bucket dir at existing copied data without moving bytes:

  ```bash
  # Existing data from NFS copy:
  #   /srv/speakasap-records/YYYY/MM/DD/lesson_<uuid>.mp3
  #
  # Expose it to MinIO as bucket 'speakasap-records':
  sudo ln -s /srv/speakasap-records /srv/minio-data/speakasap-records
  ```

## 3. Integrate with Nginx (dev)

* [ ] Reverse proxy to 127.0.0.1:9000 (e.g. `location /minio/` or subdomain)
* [ ] HTTPS via existing certificate management on dev

## 4. Initialize MinIO

* [x] Create bucket `${RECORDS_BUCKET}` (currently `speakasap-records`)
* [x] Point bucket directory at existing copied data (no byte moves) via symlink:

  ```bash
  # Existing data from NFS copy:
  #   /srv/speakasap-records/YYYY/MM/DD/lesson_<uuid>.mp3
  #
  # Expose it to MinIO as bucket 'speakasap-records':
  sudo ln -s /srv/speakasap-records /srv/minio-data/speakasap-records
  ```

* [x] Disable public access; all access via presigned URLs only

---

# PHASE 2 — MODIFY PROD BACKEND (speakasap-portal)

* [x] Integrate S3 SDK (boto3) / django-storages
* [x] Upload flow: on lesson completion → S3 PUT to bucket `records`, key `YYYY/MM/DD/lesson_UUID.mp3`
* [x] Playback flow: validate auth → generate presigned GET URL (24h) → return to client
* [x] merge_records task: support S3 (download parts from S3, merge, upload result to S3)
* [ ] No NFS removal yet

---

# PHASE 3 — VALIDATION

* [ ] Upload works; object visible in bucket
* [ ] Presigned URL works; expired URL denied
* [ ] Large file and concurrent downloads stable
* [ ] Prod CPU/disk minimal; no file descriptors blocked

---

# PHASE 4 — MIGRATION CUTOVER

* [ ] Stop writing to old filesystem path; all new uploads use S3
* [ ] Keep NFS mounted temporarily for legacy access
* [ ] Monitor logs for several days

---

# PHASE 5 — REMOVE NFS (FINAL STEP)

Only after full validation:

* [ ] Confirm no filesystem usage
* [ ] Remove NFS from `/etc/fstab`; umount records path
* [ ] Remove legacy code references

---

# SECURITY

* MinIO bound to localhost; public access only via Nginx
* Bucket private; presigned URL expiration ≤ 24 hours
* Access keys in prod environment variables only
* Firewall: restrict SSH to prod IP only

---

END OF PLAN.
