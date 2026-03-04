# MinIO Microservice (Records Storage)

S3-compatible object storage microservice for lesson records. Runs on **dev server** (85.163.140.109). Used by speakasap-portal (prod) for storing and serving lesson MP3 recordings without NFS.

## Purpose

* Replace NFS-based shared storage for course records with S3 API.
* Bucket: `records`. Object key: `YYYY/MM/DD/lesson_UUID.mp3`.
* Prod uploads via S3 PUT; playback via presigned GET URLs (no file streaming on prod).

## Deployment (Dev Server)

MinIO runs on dev only. Not deployed via statex nginx-microservice blue/green (no Docker on statex for this service).

### Prerequisites

* Dev server: 85.163.140.109, Nginx installed.
* MinIO binary or Docker (see below).

### 1. Run MinIO (systemd)

```bash
# On dev (ssh dev)
sudo scripts/setup-dev.sh   # Creates user, dir, systemd unit, installs MinIO if needed
sudo systemctl enable minio
sudo systemctl start minio
sudo systemctl status minio
```

MinIO API: `127.0.0.1:9000`, Console: `127.0.0.1:9001`. Not exposed publicly; Nginx proxies.

### 2. Nginx (dev)

Add snippet from `nginx/minio.conf` into dev Nginx config so that:

* API: e.g. `https://<dev-domain>/minio/` → `http://127.0.0.1:9000`
* Or subdomain: `https://minio.<dev-domain>` → `http://127.0.0.1:9000`

Enable HTTPS using existing certificate process on dev.

### 3. Initialize bucket

```bash
# On dev, after MinIO is running
./scripts/init-bucket.sh
```

Creates bucket `records`, disables public access. All access via presigned URLs from prod.

## Configuration

* `.env.example`: keys only (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, RECORDS_BUCKET, etc.).
* On dev: copy to `.env` and set MINIO_ROOT_USER / MINIO_ROOT_PASSWORD (strong).
* Prod (speakasap-portal): set S3 endpoint URL, bucket, access key, secret key in portal `.env` (see speakasap-portal docs).

## Access

* **From prod (speakasap-portal)**: HTTPS URL to dev MinIO (e.g. `https://85.163.140.109/minio/` or `https://minio.<dev-domain>`) with credentials in env. Portal uses S3 SDK to PUT objects and generate presigned GET URLs.
* **Direct (dev only)**: `http://127.0.0.1:9000` (API), `http://127.0.0.1:9001` (Console). Keep MinIO bound to localhost.

## Security

* MinIO listens on 127.0.0.1 only.
* Bucket `records` is private; no anonymous read.
* Presigned URL expiration ≤ 24 hours (configured in portal).
* Store MINIO_ROOT_USER / MINIO_ROOT_PASSWORD and portal S3 keys in env only; never commit.

## Integration

* See [docs/INTEGRATION.md](docs/INTEGRATION.md) for S3 API usage (PUT, presigned GET) and key layout.
* Implementation plan: [docs/MIGRATION_NFS_TO_S3_IMPLEMENTATION_PLAN.md](docs/MIGRATION_NFS_TO_S3_IMPLEMENTATION_PLAN.md).

## Standards

* Follows project README/CREATE_SERVICE conventions: README, docs/, .env.example, scripts.
* No service-registry on statex (service lives on dev).
* Logging: use central logging from applications that call MinIO (e.g. speakasap-portal); MinIO itself logs to systemd/journal.
