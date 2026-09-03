# Validation Report: TASK-002 Review Presigned URL TTL Settings

```yaml
id: VAL-TASK-002
status: reviewed
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: partial
upstream:
  - ../11_tasks/TASK-002-review-presigned-url-ttl-settings.md
execution_plan:
  - ../21_execution_plans/EP-TASK-002-review-presigned-url-ttl-settings.md
related_feature:
  - ../10_features/FEAT-002-presigned-access-boundary.md
```

## Summary
TASK-002 parallel review completed for MinIO-side documentation, policy, and validation readiness. The documented policy boundary remains that presigned URL expiration must be `<= 24 hours`, with the runtime value owned outside this MinIO repo by the consumer configuration.

## Upstream goal
Preserve private object storage while allowing bounded presigned playback access.

## Criteria checked

| Criterion | Result | Evidence |
| --- | --- | --- |
| TTL owner boundary documented | Partial | `README.md` assigns expiration configuration to the portal; external production config verification is deferred. |
| Expected maximum documented | Pass | `README.md` documents presigned URL expiration as `<= 24 hours`. |
| Secrets avoided | Pass | No `.env*`, raw tokens, authorization headers, object names, or full production presigned URLs were inspected or copied. |
| Runtime behavior unchanged | Pass | No MinIO, nginx, bucket policy, or consumer runtime change was made. |
| Validation evidence exists | Pass | TASK-002 report exists and safe gates were run. |

## Gate evidence

```bash
python3 scripts/pre_coding_gate.py --root .
python3 scripts/deployment_readiness_gate.py --root . --target TASK-002
python3 scripts/strict_doc_audit.py --format markdown --fail-on-issues
```

Gate outputs are stored under `reports/validation/`.

## Invariant evidence
MINIO-INV-001, MINIO-INV-002, MINIO-INV-003, MINIO-INV-007, MINIO-INV-008, and MINIO-INV-009 were reviewed through the parallel policy lane. The review preserves private bucket behavior, presigned-only access, sensitive-data handling, and validation evidence requirements.

## Sensitive-data scan evidence
The pre-coding gate reported no sensitive-data findings. The review did not inspect `.env*`, secret-bearing files, raw production presigned URLs, authorization headers, or production object names.

## Replay and determinism evidence
The documentation gates and strict audit are deterministic over repository files. No runtime replay behavior changed.

## Issues found
Consumer-side production TTL value verification remains outside the completed MinIO-side scope. SigV4 validation beyond documentation gates was not run because the documented script requires credentials. No MinIO-side runtime issue was found.

## Recommendation
Accept with follow-up. Keep the MinIO-side documented hard cap of `<= 24 hours`; prefer `15-60 minutes` for normal playback when URL regeneration is available. Resolve external consumer configuration facts before claiming production TTL validation.

## Traceability confirmation
The review remains aligned with the Vision -> Goal Impact -> System -> Feature -> Task -> Execution Plan -> Coding Prompt -> Validation chain for private object storage and bounded presigned access.

## Parallel Workstream Evidence

| Workstream | Result | Evidence |
| --- | --- | --- |
| TASK-002-A TTL source discovery | Complete | Found README policy statement and confirmed the effective runtime source is outside allowed MinIO repo surfaces. |
| TASK-002-B Policy and invariant review | Complete | Recommended hard cap `<= 24 hours`; preferred normal playback default `15-60 minutes`; identified external config facts. |
| TASK-002-C Validation readiness | Complete | Ran safe documentation gates and strict audit successfully; S3 signature test not run because credentials are required. |
| TASK-002-D Integration and decision | Complete for MinIO-side docs | Integrated handoffs into TASK-002 artifacts; no runtime/config change performed. |

## Resolved External Facts (2026-09-03)
- Effective production presigned TTL: **900 seconds (15 minutes)**. `portal/local_settings_default.py`
  and `portal/settings.py` both resolve `RECORDS_PRESIGNED_EXPIRY_SECONDS` to `900` when unset, and the
  production portal configuration sets the same value, so the effective TTL is 900 either way. This sits
  inside the documented cap of `<= 24 hours` and within the preferred `15-60 minutes` band, so the
  MinIO-side decision of "no change required" is now evidence-backed rather than assumed.
- Runlayer presigned URL TTL: **not applicable - runlayer does not generate presigned URLs.** It has no
  S3/MinIO client and no `aws-sdk`, `boto3` or `minio` dependency; the only superficially related matches
  are an unrelated JWT `expiresIn` in `.env.example` and a display-only expiry string in `public/app.js`.
- SigV4 validation credentials: **not required for this task.** The Test Plan scopes S3 signature tests to
  "when runtime access behavior changes", and no runtime or configuration change was made. The only MinIO
  credential held in the cluster is the root credential, which this plan's invariants forbid using. If a
  future task changes runtime access behavior, it must first obtain a scoped non-root credential.

## Tests Not Run
- `scripts/test-s3-signature.sh` was not run because the documented path requires MinIO/S3 credentials.
