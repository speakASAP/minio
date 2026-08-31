# MinIO Microservice (Records Storage)

S3-compatible object storage microservice for lesson records. Runs as the Kubernetes deployment `minio-microservice` in namespace `statex-apps` on **alfares**. Used by speakasap-portal (prod) for storing and serving lesson MP3 recordings. Data root is the canonical directory `/srv/speakasap-records` on alfares, mounted into the pod as a `hostPath` at `/data`; bucket `speakasap-records` maps to `/srv/speakasap-records/speakasap-records/YYYY/MM/DD/lesson_<uuid>.mp3`.

**Note:** speakasap-portal reaches MinIO over the **public URL** `https://minio.alfares.cz`; S3 traffic goes through the ingress, which must forward `Host` and `Authorization` unchanged for S3 SigV4.

> **Data safety — read before touching mounts**
>
> `/srv/speakasap-records` holds the live recordings (~618G). Never `mount --bind`
> another directory over it: the data is not deleted, but it becomes invisible to
> MinIO and every consumer until unmounted. MinIO's data root points at this
> directory **directly** — no bind mount is involved, and none should be added.

## Purpose

* Replace NFS-based shared storage for course records with S3 API.
* Bucket: `RECORDS_BUCKET` (currently `speakasap-records`). Object key: `YYYY/MM/DD/lesson_UUID.mp3`.
* Prod uploads via S3 PUT; playback via presigned GET URLs (no file streaming on prod).

## Deployment (Kubernetes)

MinIO runs as a k8s deployment in namespace `statex-apps`. There is **no** systemd
unit and **no** Docker blue/green flow for this service; both are historical and
were removed. Manifests live in `k8s/`.

```bash
./scripts/deploy.sh                 # build + apply k8s manifests
kubectl get pods -n statex-apps -l app=minio-microservice
kubectl logs  -n statex-apps -l app=minio-microservice -f
kubectl rollout restart deployment/minio-microservice -n statex-apps
```

Committing to `main` deploys automatically via the shared deploy queue; a manual
`deploy.sh` run is only needed for a rollback or an explicit redeploy.

* **API port:** 9000 (ClusterIP `minio-microservice`), public via `https://minio.alfares.cz`
* **Data:** `hostPath` `/srv/speakasap-records` → `/data` in the pod
* **Secrets:** Vault `secret/prod/minio-microservice`, synced by ESO to Secret `minio-microservice-secret`

### Bucket creation

```bash
./scripts/init-bucket.sh            # needs MinIO Client as `minio-mc` and .env credentials
```

Install the client as `minio-mc` to avoid a conflict with Midnight Commander (`mc`):

```bash
wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/minio-mc && chmod +x /usr/local/bin/minio-mc
```

### Local development

`scripts/setup-dev.sh` provisions a **host-level** MinIO (own user, systemd unit,
data dir) for a dev machine only. It refuses to run where the k8s deployment
exists or where `/srv/speakasap-records` already contains data.

> **Data root**
> MinIO's data root is the **canonical records directory** `/srv/speakasap-records`,
> mounted into the pod as a `hostPath` volume at `/data` (see `k8s/deployment.yaml`).
>
> MinIO metadata lives under:
>
> * `/srv/speakasap-records/.minio`
> * `/srv/speakasap-records/.minio.sys`
>
> Bucket `speakasap-records` is a directory under that root:
>
> * `/srv/speakasap-records/speakasap-records/YYYY/MM/DD/lesson_<uuid>.mp3`
>
> **Do not place mounts or symlinks under `/data`** (inside the container) – MinIO requires that `.minio.sys` and all bucket paths live on the same filesystem. Sub-mounts or cross-device symlinks under `/data` will cause errors such as `Rename across devices not allowed` and S3 `AllAccessDisabled`.

With `RECORDS_BUCKET=speakasap-records` and object keys `YYYY/MM/DD/lesson_<uuid>.mp3`, files are at:

* `/srv/speakasap-records/speakasap-records/YYYY/MM/DD/lesson_<uuid>.mp3` on alfares (canonical copy)
* Exposed via S3 as `speakasap-records/YYYY/MM/DD/lesson_<uuid>.mp3`.

### 2. Nginx (alfares)

Add snippet from `nginx/minio.conf` into alfares Nginx config so that:

* API: e.g. `https://<alfares-domain>/minio/` → `http://127.0.0.1:9000`
* Or subdomain: `https://minio.<alfares-domain>` → `http://127.0.0.1:9000`

Enable HTTPS using existing certificate process on alfares.

### 3. Initialize bucket

```bash
# On alfares, after MinIO is running
./scripts/init-bucket.sh
```

Creates bucket `${RECORDS_BUCKET}` (defaults to `speakasap-records` when using `/srv/minio/.env`), disables public access. All access via presigned URLs from prod.

### 4. Check MinIO (diagnose AllAccessDisabled / 500)

```bash
# On alfares
ssh alfares
cd minio-microservice   # or cd /home/ssf/Documents/Github/minio-microservice
./scripts/check-minio.sh
```

Verifies: MinIO process or Docker, port 9000, .env keys, bucket list, anonymous policy, and a test PUT. If test PUT fails, fix bucket policy or credentials so the portal can upload.

### 5. Diagnose 520 / Nginx / certificates on alfares

```bash
ssh alfares
cd /home/ssf/Documents/Github/minio-microservice
./scripts/diagnose-minio-dev.sh
```

Runs: MinIO status, direct PUT to MinIO (127.0.0.1:9000), Nginx config grep, PUT via Nginx with Host header, HTTPS PUT to the MinIO hostname, SSL cert check, last Nginx errors. Use this when prod gets 520 or Method Not Allowed to see if the issue is MinIO, Nginx proxy, or SSL on alfares.

### 6. Request diagnostics (SignatureDoesNotMatch, etc.)

After reproducing an upload error from the portal, run on **alfares** to see what MinIO and Nginx logged:

```bash
ssh alfares
cd /path/to/minio-microservice
./scripts/log-request-diagnostics.sh
```

Shows: last 80 lines of MinIO container log, Nginx access log lines for minio.alfares.cz/records/, Nginx error log. Compare with portal logs: `grep RECORDS_S3 ~/speakasap-portal/logs/app.log` on **speakasap** (endpoint, path, secret_len). For SignatureDoesNotMatch, ensure Host and path at MinIO match what the portal used to sign.

### 7. S3 SigV4 signature test (PUT + GET)

Run after **redeploy** to verify two-way S3 (PUT then GET, same as portal):

```bash
# On alfares (or prod host that can reach MinIO):
cd /path/to/minio-microservice
./scripts/test-s3-signature.sh
```

* **Test 1 (direct)**: PUT then GET to `http://127.0.0.1:9000` with SigV4 path-style. Expect: `PUT OK`, `GET OK`, `DELETE OK`, then `Direct: OK`. MinIO must be running (e.g. Docker).
* **Test 2 (via Nginx)**: PUT then GET to `https://minio.alfares.cz`. Expect: `PUT OK`, `GET OK`, then `Via Nginx: OK`. If you see "authorization mechanism not supported", the proxy is altering/stripping the Authorization header; ensure nginx forwards `Host` and `Authorization` (see `nginx/minio.conf`).
* **Test 3**: Last 30 lines of MinIO server logs (when MinIO runs in Docker or systemd).

Optional: `S3_TEST_VERBOSE=1 ./scripts/test-s3-signature.sh` prints endpoint and bucket before each test. To use portal credentials: set `S3_ENDPOINT_URL`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_BUCKET` from portal `.env` (RECORDS_S3_*) then run the script. To skip the Nginx test (e.g. local/CI when minio.alfares.cz is not deployed): `S3_TEST_SKIP_NGINX=1 ./scripts/test-s3-signature.sh`; the script exits 1 if any run test fails.

Uses system python3+boto3, or repo venv `.venv-signature-test`, or Docker (python:3.11-slim) if boto3 is not installed.

## Customer Web Surface

The customer and administrator web UI is implemented as a separate static surface under `web/` and is served from `https://storage.alfares.cz`: landing at `/`, client dashboard at `/client/`, and admin panel at `/admin/`. Do not serve the landing page from `https://minio.alfares.cz/`: that host root remains the S3 path-style endpoint and must preserve SigV4 host, path, authorization, and method semantics.

The first web implementation includes:

* Landing page with pricing, conversion copy, and consultation CTA.
* Leads intake form posting to `https://leads.alfares.cz/api/leads/submit` with `sourceService=minio-microservice`.
* Auth registration/login handoff through `https://auth.alfares.cz` with `client_id=minio-microservice`.
* Customer dashboard at `/client/` for application onboarding drafts and safe S3 connection parameters.
* Admin panel at `/admin/` that hides operational data until Auth `/auth/validate` returns `global:superadmin`, `app:minio-microservice:admin`, or `internal:minio-microservice:admin`.
* Mock customer/admin metrics only; real object inventory, usage and settings require a protected backend wrapper.

Privileged MinIO object inventory, bucket mutation, credential issuance, and real storage metrics require a protected backend wrapper. The static browser UI intentionally does not expose MinIO root credentials, raw access tokens, private object inventories, or production presigned URLs.

## Protected Admin Wrapper

The first backend wrapper slice is implemented as a read-only administrator API under `storage.alfares.cz/api/admin`. It validates the browser Bearer token through Auth and requires one of `global:superadmin`, `app:minio-microservice:admin`, or `internal:minio-microservice:admin` before returning metadata.

Current endpoints:

* `GET /healthz`: public Kubernetes health probe.
* `GET /api/admin/summary`: bucket name, object count, total bytes, and newest object timestamp.
* `GET /api/admin/objects?prefix=&limit=25`: bounded object metadata listing with key, size, content type, and modified timestamp.

The wrapper mounts `/srv/speakasap-records` read-only, does not use or return MinIO root credentials, does not stream object bodies, does not generate presigned URLs, and does not mutate buckets or credentials. Mutation and credential issuance require a separate traced task and validation plan.

## Configuration

* `.env.example`: keys only (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD, RECORDS_BUCKET, etc.).
* On dev: copy to `.env` and set MINIO_ROOT_USER / MINIO_ROOT_PASSWORD (strong).
* Prod (speakasap-portal): set S3 endpoint URL (root only), bucket, access key, secret key in portal `.env` (see speakasap-portal docs). Use the root URL so SigV4 path matches what MinIO receives:

  ```env
  RECORDS_S3_ENDPOINT_URL=https://minio.alfares.cz
  RECORDS_S3_BUCKET=speakasap-records
  ```

* If init-bucket.sh reports "signature does not match": use the same credentials as the MinIO server (systemd uses `/srv/minio/.env`). Ensure `.env` has Unix line endings (LF, not CRLF).

## Access

* **From prod (speakasap-portal)**: HTTPS URL to dev MinIO via the public hostname (currently `https://minio.alfares.cz`, fronted by nginx-microservice) with credentials in env. Portal uses S3 SDK to PUT objects and generate presigned GET URLs.
* **Direct (dev only)**: `http://127.0.0.1:9000` (API), `http://127.0.0.1:9001` (Console). Keep MinIO bound to localhost.

## Security

* MinIO listens on 127.0.0.1 only; external access is only via nginx-microservice / Cloudflare on `https://minio.alfares.cz`.
* Bucket `speakasap-records` is private; no anonymous read.
* Presigned URL expiration ≤ 24 hours (configured in portal).
* Store MINIO_ROOT_USER / MINIO_ROOT_PASSWORD and portal S3 keys in env only; never commit.

## Integration

* See [docs/INTEGRATION.md](docs/INTEGRATION.md) for S3 API usage (PUT, presigned GET) and key layout.
* Implementation plan: [docs/MIGRATION_NFS_TO_S3_IMPLEMENTATION_PLAN.md](docs/MIGRATION_NFS_TO_S3_IMPLEMENTATION_PLAN.md).

## Browser Presigned Uploads (CORS)

For OSS MinIO, browser CORS is configured globally via MinIO API config (not bucket-level `PutBucketCors`).

- Allowed origins are configured by `RECORDS_CORS_ORIGINS` (comma-separated), default:
  - `https://speakasap.com,https://www.speakasap.com`
- Deployment maps `RECORDS_CORS_ORIGINS` to `MINIO_API_CORS_ALLOW_ORIGIN`.
- Manual apply (if needed): `./scripts/set-bucket-cors.sh` (sets `api.cors_allow_origin`).

## Standards

* Follows project README/CREATE_SERVICE conventions: README, docs/, .env.example, scripts.
* No service-registry on statex (service lives on alfares).
* Logging: use central logging from applications that call MinIO (e.g. speakasap-portal); MinIO itself logs to systemd/journal.

## Troubleshooting uploads from speakasap-portal

If `speakasap-portal` reports helper 500s or `NoSuchBucket` errors when calling `PutObject` to `https://minio.alfares.cz`:

**Playback "Could not connect to the server" / NotSupportedError**

The teacher/manager play button redirects the browser to a presigned URL on `https://minio.alfares.cz/...`. If the browser cannot reach that host (firewall, DNS, or HTTPS not exposed), you get connection failure and NotSupportedError.

* Ensure `minio.alfares.cz` is reachable from the **client** (teacher’s browser): open `https://minio.alfares.cz` in a new tab from the same machine; or run `curl -I https://minio.alfares.cz` from that network.
* CORS is added by deploy so the portal origin can load the audio; redeploy MinIO to apply it.

### Nginx API routes and deploy patches

* `nginx/nginx-api-routes.conf` registers `/`, `/minio/`, and `/records/`. Root `/` is required for path-style S3 when the portal uses `https://minio.alfares.cz` (no path prefix).
* `scripts/deploy.sh` after deploy: patches generated configs to use `minio-proxy-settings.conf` (SigV4 headers), strips `/minio` prefix in the `/minio/` location so MinIO sees path-style keys, and adds CORS headers so the browser can play presigned GET responses.

0. **AllAccessDisabled ("All access to this resource has been disabled")**

   This usually means MinIO cannot:

   * Write to its metadata or bucket directory, **or**
   * Atomically move objects from `.minio.sys/tmp` into the bucket because the bucket path lives on a **different filesystem** (cross-device rename).

   Fix on the **host that actually serves minio.alfares.cz** (where the MinIO that receives the portal's requests runs).

   **Confirm which host serves the URL:** From speakasap or your laptop run `getent hosts minio.alfares.cz` or `dig +short minio.alfares.cz`. The IP is the host that must have correct permissions and a running MinIO.

   If MinIO logs show:

   ```text
   Error: Rename across devices not allowed, please fix your backend configuration
   FATAL Invalid command line arguments: Cross-device mounts detected on path (/data) ...
   ```

   then there is a **sub-mount or cross-device symlink under `/data`**. Remove any mounts/symlinks inside the MinIO data root and keep all bucket directories on the same filesystem (see data-root section above).

   **On the host that serves minio.alfares.cz** (e.g. statex):

   * **Docker MinIO** (typical when deployed via `./scripts/deploy.sh` on alfares): the container uses `/srv/speakasap-records` on that host as its data root:

     ```yaml
     volumes:
       - /srv/speakasap-records:/data
     ```

     Ensure ownership and permissions:

     ```bash
     sudo chown -R minio:minio /srv/speakasap-records
     sudo chmod -R u+rwX /srv/speakasap-records
     kubectl rollout restart deployment/minio-microservice -n statex-apps
     ```

   **After any permission fix, restart the pod** so MinIO clears cached error state.

   Then on the portal host:

   ```bash
   ssh speakasap
   supervisorctl -c /vagrant/setup/supervisord.conf restart records_s3_helper
   cd ~/speakasap-portal && python3 scripts/verify_s3_records_upload.py
   ```

   Expect helper 200 and "S3 upload path OK".

1. **Verify bucket and credentials directly from alfares:**

   ```bash
   ssh alfares
   cd /home/ssf/Documents/Github/minio-microservice
   ./scripts/test-s3-signature.sh
   ```

   * Test 1 must show `PUT OK` / `GET OK` against `http://127.0.0.1:9000` and bucket `speakasap-records`.

2. **Run request diagnostics after reproducing the error from the portal:**

   ```bash
   ssh alfares
   cd /home/ssf/Documents/Github/minio-microservice
   ./scripts/log-request-diagnostics.sh
   ```

   * Check MinIO logs for the exact bucket/key and error code.
   * Confirm that nginx is forwarding `Host` and `Authorization` unchanged and that the request reaches the MinIO instance backing `speakasap-records`.

3. **On the portal host (`speakasap`), re-run the verification helper:**

   ```bash
   ssh speakasap
   cd /home/portal_db/speakasap-portal
   python3 scripts/verify_s3_records_upload.py
   ```

   * When correctly configured, this should return HTTP 200 from the helper and a successful `head_object` on the same bucket/key in MinIO.

### MinIO pod not starting

```bash
kubectl get pods    -n statex-apps -l app=minio-microservice
kubectl describe pod -n statex-apps -l app=minio-microservice
kubectl logs        -n statex-apps -l app=minio-microservice --tail=50
```

* **Ownership:** the container runs as **root** (no `securityContext` is set), so it
  can write regardless of owner. The data files are owned by `995:982` — the legacy
  host `minio` user — which is inert while the pod runs as root, but matters if a
  non-root `securityContext` is ever added: set `runAsUser: 995` to match, or chown
  the data first.
* **Port 9000:** owned by the pod. Nothing on the host should bind it — a host-level
  MinIO would conflict, which is why `setup-dev.sh` refuses to install one here.
* **Secrets:** if the pod starts then crashes on credentials, check the ExternalSecret
  synced (`kubectl get externalsecret -n statex-apps`); a sealed Vault breaks the sync.

Then, on the portal side: `supervisorctl -c /vagrant/setup/supervisord.conf restart records_s3_helper` and `python3 scripts/verify_s3_records_upload.py`.\n\n---\n\n# minio-microservice
Private S3-compatible MinIO storage for lesson recordings and task artifacts.
## Status
Production service in `statex-apps`; canonical IPS adoption is validated.
## Documentation Authority
BUSINESS.md, approved constitution, vision, SYSTEM.md, and ips-adoption.json are authoritative.
## Capabilities
Private MinIO S3 storage, presigned GET access, console, and an authenticated read-only metadata wrapper.
## Interfaces
S3: 9000/9002; console: 9001/9003; production: `https://minio.alfares.cz`; wrapper health: `/healthz`.
## Development
Use existing scripts and safe S3 signature checks for storage, CORS, endpoint, or proxy changes.
## Configuration
Vault path `secret/prod/minio-microservice` is synchronized through External Secrets Operator; never commit credentials.
## Deployment
`./scripts/deploy.sh` deploys to `statex-apps` using upstream MinIO runtime images.
## Health and Observability
MinIO probes use `/minio/health/live`; wrapper probes use `/healthz` and wrapper events go to logging-microservice.
