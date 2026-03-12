# MinIO Microservice (Records Storage)

S3-compatible object storage microservice for lesson records. Runs on **dev server** (85.163.140.109). Used by speakasap-portal (prod) for storing and serving lesson MP3 recordings without NFS. MinIO stores lesson MP3s in a bucket that points to the existing copied data under `/srv/speakasap-records/YYYY/MM/DD/lesson_<uuid>.mp3` on dev (no NFS dependency).

**Note:** The portal (speakasap) and MinIO are on **different servers**; they do not share an internal network. The portal must use the **public MinIO URL** (e.g. `https://minio.alfares.cz`), and all S3 traffic goes through the proxy. The proxy must forward `Host` and `Authorization` unchanged for S3 SigV4 (see `nginx/minio.conf` and deploy).

## Purpose

* Replace NFS-based shared storage for course records with S3 API.
* Bucket: `RECORDS_BUCKET` (currently `speakasap-records`). Object key: `YYYY/MM/DD/lesson_UUID.mp3`.
* Prod uploads via S3 PUT; playback via presigned GET URLs (no file streaming on prod).

## Deployment (Dev Server)

MinIO runs on dev only as the backing store for lesson records. nginx-microservice fronts it via HTTPS (`https://minio.alfares.cz`). The deploy script patches the generated nginx config so that `minio.alfares.cz` proxies to **host systemd MinIO** at `host.docker.internal:9000` (not the MinIO Docker container). The nginx container must resolve `host.docker.internal` (e.g. run with `--add-host=host.docker.internal:host-gateway` or set `extra_hosts: - "host.docker.internal:host-gateway"` in its compose).

### Prerequisites

* Dev server: 85.163.140.109, Nginx installed.
* MinIO binary at `/usr/local/bin/minio` (setup-dev.sh warns if missing; install manually).
* MinIO Client (`minio-mc`) for init-bucket.sh: <https://min.io/docs/minio/linux/reference/minio-mc.html>  
  If the system has Midnight Commander (package `mc`), install the MinIO client as `minio-mc` to avoid conflict:  
  `wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/minio-mc && chmod +x /usr/local/bin/minio-mc`

### Initial deployment (first time)

Run on **dev server** in this order:

1. **Setup** (user, dirs, systemd, .env):

   ```bash
   cd /path/to/minio
   sudo scripts/setup-dev.sh
   ```

2. **Install MinIO binary** if not present (setup-dev.sh will warn):

   ```bash
   sudo wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio
   sudo chmod +x /usr/local/bin/minio
   sudo chown minio:minio /usr/local/bin/minio
   ```

3. **Set credentials** in `/srv/minio/.env` (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD).

4. **Enable and start MinIO**:

   ```bash
   sudo systemctl enable minio
   sudo systemctl start minio
   sudo systemctl status minio
   ```

5. **Create bucket** (requires MinIO Client as `minio-mc` (preferred) or `mc` when it is the MinIO client, and .env with credentials):

   ```bash
   cd /path/to/minio
   ./scripts/init-bucket.sh
   ```

6. **Optional – Nginx (dev)**: when MinIO is behind nginx-microservice, `nginx/nginx-api-routes.conf` must list `/minio/` and `/records/` (not `/`, which would replace the URI and break S3). After changing it, redeploy via `./scripts/deploy.sh`.

7. **Optional – deploy.sh**: only if MinIO is later added to nginx-microservice on statex (per this README, MinIO runs on dev only; deploy.sh is for blue/green on statex).

### 1. Run MinIO (systemd)

```bash
# On dev (ssh dev)
sudo scripts/setup-dev.sh   # Creates user, dir, systemd unit, installs MinIO if needed
sudo systemctl enable minio
sudo systemctl start minio
sudo systemctl status minio
```

MinIO API: `127.0.0.1:9000`, Console: `127.0.0.1:9001`. Not exposed publicly; Nginx proxies. MinIO data dir is **`/srv/minio-data`** (systemd and Docker). The bucket directory for lesson records is configured to point at the existing copy under `/srv/speakasap-records` via symlink:

```bash
# On dev (after creating /srv/speakasap-records and copying NFS data there):
sudo ln -s /srv/speakasap-records /srv/minio-data/speakasap-records
```

With `RECORDS_BUCKET=speakasap-records` and object keys `YYYY/MM/DD/lesson_<uuid>.mp3`, files are at:

* `/srv/speakasap-records/YYYY/MM/DD/lesson_<uuid>.mp3` on dev (canonical copy)
* Exposed via S3 as `speakasap-records/YYYY/MM/DD/lesson_<uuid>.mp3`.

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

Creates bucket `${RECORDS_BUCKET}` (defaults to `speakasap-records` when using `/srv/minio/.env`), disables public access. All access via presigned URLs from prod.

### 4. Check MinIO (diagnose AllAccessDisabled / 500)

```bash
# On dev
ssh dev
cd minio-microservice   # or cd /home/ssf/Documents/Github/minio-microservice
./scripts/check-minio.sh
```

Verifies: MinIO process or Docker, port 9000, .env keys, bucket list, anonymous policy, and a test PUT. If test PUT fails, fix bucket policy or credentials so the portal can upload.

### 5. Diagnose 520 / Nginx / certificates on dev

```bash
ssh dev
cd /home/ssf/Documents/Github/minio-microservice
./scripts/diagnose-minio-dev.sh
```

Runs: MinIO status, direct PUT to MinIO (127.0.0.1:9000), Nginx config grep, PUT via Nginx with Host header, HTTPS PUT to the MinIO hostname, SSL cert check, last Nginx errors. Use this when prod gets 520 or Method Not Allowed to see if the issue is MinIO, Nginx proxy, or SSL on dev.

### 6. Request diagnostics (SignatureDoesNotMatch, etc.)

After reproducing an upload error from the portal, run on **dev** to see what MinIO and Nginx logged:

```bash
ssh dev
cd /path/to/minio-microservice
./scripts/log-request-diagnostics.sh
```

Shows: last 80 lines of MinIO container log, Nginx access log lines for minio.alfares.cz/records/, Nginx error log. Compare with portal logs: `grep RECORDS_S3 ~/speakasap-portal/logs/app.log` on **speakasap** (endpoint, path, secret_len). For SignatureDoesNotMatch, ensure Host and path at MinIO match what the portal used to sign.

### 7. S3 SigV4 signature test (PUT + GET)

Run after **redeploy** to verify two-way S3 (PUT then GET, same as portal):

```bash
# On dev (or prod host that can reach MinIO):
cd /path/to/minio-microservice
./scripts/test-s3-signature.sh
```

* **Test 1 (direct)**: PUT then GET to `http://127.0.0.1:9000` with SigV4 path-style. Expect: `PUT OK`, `GET OK`, `DELETE OK`, then `Direct: OK`. MinIO must be running (e.g. Docker).
* **Test 2 (via Nginx)**: PUT then GET to `https://minio.alfares.cz`. Expect: `PUT OK`, `GET OK`, then `Via Nginx: OK`. If you see "authorization mechanism not supported", the proxy is altering/stripping the Authorization header; ensure nginx forwards `Host` and `Authorization` (see `nginx/minio.conf`).
* **Test 3**: Last 30 lines of MinIO server logs (when MinIO runs in Docker or systemd).

Optional: `S3_TEST_VERBOSE=1 ./scripts/test-s3-signature.sh` prints endpoint and bucket before each test. To use portal credentials: set `S3_ENDPOINT_URL`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_BUCKET` from portal `.env` (RECORDS_S3_*) then run the script. To skip the Nginx test (e.g. local/CI when minio.alfares.cz is not deployed): `S3_TEST_SKIP_NGINX=1 ./scripts/test-s3-signature.sh`; the script exits 1 if any run test fails.

Uses system python3+boto3, or repo venv `.venv-signature-test`, or Docker (python:3.11-slim) if boto3 is not installed.

## Configuration

* `.env.example`: keys only (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, RECORDS_BUCKET, etc.).
* On dev: copy to `.env` and set MINIO_ROOT_USER / MINIO_ROOT_PASSWORD (strong).
* Prod (speakasap-portal): set S3 endpoint URL, bucket, access key, secret key in portal `.env` (see speakasap-portal docs). Currently:

  ```env
  RECORDS_S3_ENDPOINT_URL=https://minio.alfares.cz/minio/
  RECORDS_S3_BUCKET=speakasap-records
  ```

* If init-bucket.sh reports "signature does not match": use the same credentials as the MinIO server (systemd uses `/srv/minio/.env`). Ensure `.env` has Unix line endings (LF, not CRLF).

## Access

* **From prod (speakasap-portal)**: HTTPS URL to dev MinIO via the public hostname (currently `https://minio.alfares.cz`, fronted by nginx-microservice) with credentials in env. Portal uses S3 SDK to PUT objects and generate presigned GET URLs.
* **Direct (dev only)**: `http://127.0.0.1:9000` (API), `http://127.0.0.1:9001` (Console). Keep MinIO bound to localhost.

## Security

* MinIO listens on 127.0.0.1 only; external access is only via nginx-microservice on `https://minio.alfares.cz`.
* Bucket `speakasap-records` is private; no anonymous read.
* Presigned URL expiration ≤ 24 hours (configured in portal).
* Store MINIO_ROOT_USER / MINIO_ROOT_PASSWORD and portal S3 keys in env only; never commit.

## Integration

* See [docs/INTEGRATION.md](docs/INTEGRATION.md) for S3 API usage (PUT, presigned GET) and key layout.
* Implementation plan: [docs/MIGRATION_NFS_TO_S3_IMPLEMENTATION_PLAN.md](docs/MIGRATION_NFS_TO_S3_IMPLEMENTATION_PLAN.md).

## Standards

* Follows project README/CREATE_SERVICE conventions: README, docs/, .env.example, scripts.
* No service-registry on statex (service lives on dev).
* Logging: use central logging from applications that call MinIO (e.g. speakasap-portal); MinIO itself logs to systemd/journal.
